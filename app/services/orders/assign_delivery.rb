module Orders
  class AssignDelivery
    def self.call(order:, assigned_to:, assigned_by:)
      ActiveRecord::Base.transaction do
        order.update!(assigned_to: assigned_to)
        order.delivery_events.create!(
          status:     :assigned,
          created_by: assigned_by,
          note:       "Assigned to #{assigned_to.full_name}"
        )
      end

      OrderMailer.delivery_assigned(order, assigned_to).deliver_later

      order
    end
  end
end
