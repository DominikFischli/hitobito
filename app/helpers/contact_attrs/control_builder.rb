#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactAttrs
  class ControlBuilder
    include ActionView::Helpers::OutputSafetyHelper

    def initialize(form, entity)
      @f = form
      @entity = entity
    end

    def render(include_contact_assoc = true)
      to_render = include_contact_assoc ? [mandatory_contact_attrs, configurable_contact_attrs, possible_contact_associations] : [mandatory_contact_attrs, configurable_contact_attrs]
      safe_join to_render
    end

    private

    delegate :t, to: I18n
    delegate :radio_button_tag, :check_box_tag, :hidden_field_tag, to: "f.template"

    attr_reader :f, :entity

    def entity_class
      entity.model.class
    end

    def entity_name
      /[a-z]*/.match entity_class.name.downcase
    end

    def mandatory_contact_attrs
      entity_class.mandatory_contact_attrs.collect do |a|
        f.labeled(a, attr_label(a)) do
          radio_buttons(a, true, [:required])
        end
      end
    end

    def configurable_contact_attrs
      non_mandatory_contact_attrs.collect do |a|
        f.labeled(a, attr_label(a)) do
          radio_buttons(a)
        end
      end
    end

    def non_mandatory_contact_attrs
      entity_class.possible_contact_attrs - entity_class.mandatory_contact_attrs
    end

    def possible_contact_associations
      entity_class.possible_contact_associations.collect do |a|
        f.labeled(a, attr_label(a)) do
          assoc_checkbox(a)
        end
      end
    end

    def radio_buttons(attr, disabled = false, options = [:required, :optional, :hidden])
      buttons = options.collect do |o|
        checked = options.size == 1
        radio_button(attr, disabled, o, checked)
      end
      safe_join(buttons)
    end

    def radio_button(attr, disabled, option, checked = false)
      f.label("#{for_label(attr)}_#{option}", class: "radio inline mt-2") do
        checked ||= checked?(attr, option)
        options = {disabled: disabled, checked: checked, class: "me-2"}
        radio_button_tag(for_name(attr), option, options) +
          option_label(option)
      end
    end

    def assoc_checkbox(assoc)
      f.label(for_label(assoc), class: "checkbox inline") do
        hidden_field_tag(for_name(assoc), 0, id: for_name(assoc) + "_hidden") +
          check_box_tag(for_name(assoc), :hidden, assoc_hidden?(assoc), class: "me-2 mt-2") +
          option_label(:hidden)
      end
    end

    def assoc_hidden?(assoc)
      entity.hidden_contact_attrs.include?(assoc.to_s)
    end

    def checked?(attr, option)
      attr = attr.to_s
      required = entity.required_contact_attrs.include?(attr)
      hidden = entity.hidden_contact_attrs.include?(attr)
      return required if option == :required
      return hidden if option == :hidden
      !required && !hidden
    end

    def for_name(attr)
      "#{entity_name}[contact_attrs][#{attr}]"
    end

    def for_label(attr)
      "contact_attrs_#{attr}"
    end

    def option_label(option)
      t("activerecord.attributes.#{entity_name}/contact_attrs.#{option}")
    end

    def attr_label(attr)
      t("activerecord.attributes.person.#{attr}")
    end
  end
end
