#  Copyright (c) 2025 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactAttrs
  extend ActiveSupport::Concern

  ALLOWED_VISIBLE_CONTACT_ATTRIBUTES = %w[
    name
    address
    phone_number
    email
    social_account
  ].freeze

  included do
    class_attribute :mandatory_contact_attrs,
      :possible_contact_attrs,
      :possible_contact_associations

    self.mandatory_contact_attrs = [:email, :first_name, :last_name]

    self.possible_contact_attrs = [:first_name, :last_name, :nickname, :company_name, :email,
      :address_care_of, :street, :housenumber, :postbox, :zip_code, :town, :country,
      :gender, :birthday, :phone_numbers, :language]

    self.possible_contact_associations = [:additional_emails, :social_accounts]

    ### VALIDATIONS
    validate :assert_required_contact_attrs_valid
    validate :assert_hidden_contact_attrs_valid
    validate :validate_visible_contact_attributes
  end

  def show_contact_attr_address
    (contact_attribute_keys & [:street, :housenumber]).any?
  end

  def show_contact_attr?(a)
    contact_attribute_keys.include?(a)
  end

  def required_contact_attr?(a)
    required = required_contact_attrs.map(&:to_sym) + self.class.mandatory_contact_attrs
    required.include?(a.to_sym)
  end

  def contact_attribute_keys
    self.class.possible_contact_attrs - hidden_contact_attrs.collect(&:to_sym)
  end

  def valid_contact_attr?(attr)
    (
      self.class.possible_contact_attrs +
      self.class.possible_contact_associations
    ).map(&:to_s).include?(attr.to_s)
  end

  def assert_required_contact_attrs_valid # rubocop:disable Metrics/CyclomaticComplexity
    required_contact_attrs.map(&:to_s).each do |a|
      unless valid_contact_attr?(a) &&
          self.class.possible_contact_associations
              .map(&:to_s).exclude?(a)
        errors.add(:base, :contact_attr_invalid, attribute: a)
      end

      if hidden_contact_attrs.include?(a)
        errors.add(:base, :contact_attr_hidden_required, attribute: a)
      end
    end
  end

  def assert_hidden_contact_attrs_valid
    hidden_contact_attrs.map(&:to_sym).each do |a|
      unless valid_contact_attr?(a)
        errors.add(:base, :contact_attr_invalid, attribute: a)
      end
      if self.class.mandatory_contact_attrs.include?(a)
        errors.add(:base, :contact_attr_mandatory, attribute: a)
      end
    end
  end

  def validate_visible_contact_attributes
    return if visible_contact_attributes.blank? || contact_id.blank?

    unless visible_contact_attributes.all? { |attr|
      ALLOWED_VISIBLE_CONTACT_ATTRIBUTES.include?(attr)
    }
      errors.add(:visible_contact_attributes, :inclusion)
    end
  end
end
