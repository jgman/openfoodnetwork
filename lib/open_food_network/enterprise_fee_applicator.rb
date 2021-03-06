module OpenFoodNetwork
  class EnterpriseFeeApplicator < Struct.new(:enterprise_fee, :variant, :role)
    def create_line_item_adjustment(line_item)
      a = enterprise_fee.create_adjustment(line_item_adjustment_label, line_item.order, line_item, true)

      AdjustmentMetadata.create! adjustment: a, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: role

      a.set_absolute_included_tax! adjustment_tax(line_item, a)
    end

    def create_order_adjustment(order)
      a = enterprise_fee.create_adjustment(order_adjustment_label, order, order, true)

      AdjustmentMetadata.create! adjustment: a, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: role

      a.set_absolute_included_tax! adjustment_tax(order, a)
    end


    private

    def line_item_adjustment_label
      "#{variant.product.name} - #{base_adjustment_label}"
    end

    def order_adjustment_label
      "#{I18n.t(:enterprise_fee_whole_order)} - #{base_adjustment_label}"
    end

    def base_adjustment_label
      I18n.t(:enterprise_fee_by, type: enterprise_fee.fee_type, role: role, enterprise_name: enterprise_fee.enterprise.name)
    end

    def adjustment_tax(adjustable, adjustment)
      tax_rates = TaxRateFinder.tax_rates_of(adjustment)

      tax_rates.select(&:included_in_price).sum do |rate|
        rate.compute_tax adjustment.amount
      end
    end
  end
end
