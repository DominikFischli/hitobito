class AddConfigurableSelfRegistrationAttrsToGroup < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :hidden_contact_attrs, :text
    add_column :groups, :required_contact_attrs, :text
    add_column :groups, :visible_contact_attributes, :string, default: '["name", "address", "phone_number", "email", "social_account"]'
  end
end
