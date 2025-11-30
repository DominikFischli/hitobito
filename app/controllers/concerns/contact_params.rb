#  Copyright (c) 2025 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactParams
  extend ActiveSupport::Concern

  def reset_contact_attrs
    entry.required_contact_attrs = []
    entry.hidden_contact_attrs = []
  end

  def assign_contact_attrs
    contact_attrs = model_params.delete(:contact_attrs)
    return if contact_attrs.blank?

    reset_contact_attrs
    contact_attrs.each do |a, v|
      entry.required_contact_attrs << a if v.to_sym == :required
      entry.hidden_contact_attrs << a if v.to_sym == :hidden
    end
  end

  def assign_visible_contact_attrs
    contact_attrs = model_params.delete(:visible_contact_attributes).presence

    entry.visible_contact_attributes =
      case contact_attrs
      when Hash, ActionController::Parameters then contact_attrs.keys
      when Array then contact_attrs
      when nil then []
      else
        raise "Unexpected Type for visible_contact_attributes: #{contact_attrs.class}"
      end
  end
end
