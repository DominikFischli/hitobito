# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: invoices
#
#  id                :integer          not null, primary key
#  title             :string(255)      not null
#  sequence_number   :string(255)      not null
#  state             :string(255)      default("draft"), not null
#  esr_number        :string(255)      not null
#  description       :text(65535)
#  recipient_email   :string(255)
#  recipient_address :text(65535)
#  sent_at           :date
#  due_at            :date
#  group_id          :integer          not null
#  recipient_id      :integer          not null
#  total             :decimal(12, 2)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Invoice < ActiveRecord::Base
  include I18nEnums

  attr_accessor :recipient_ids

  STATES = %w(draft sent payed overdue reminded cancelled).freeze

  belongs_to :group
  belongs_to :recipient, class_name: 'Person'
  has_many :invoice_items, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :payment_reminders, dependent: :destroy

  before_validation :set_sequence_number, on: :create, if: :group
  before_validation :set_esr_number, on: :create, if: :group
  before_validation :set_dates, on: :update, if: :sent_state?
  before_validation :set_recipient_fields, on: :create, if: :recipient
  before_validation :set_self_in_nested
  before_validation :recalculate

  validates :state, inclusion: { in: STATES }
  validates :due_at, timeliness: { after: :sent_at }, if: :sent?
  validates :due_at, presence: true, if: :sent?

  after_create :increment_sequence_number
  after_create :set_recipient_fields

  accepts_nested_attributes_for :invoice_items, allow_destroy: true

  i18n_enum :state, STATES

  validates_by_schema

  scope :list,       -> { where.not(state: :cancelled).order(:sequence_number) }
  scope :draft,      -> { where(state: :draft) }
  scope :sent,       -> { where(state: :sent) }

  def multi_create
    Invoice.transaction do
      all_saved = recipients.all? do |recipient|
        invoice = self.class.new(attributes.merge(recipient_id: recipient.id))
        invoice_items.each do |invoice_item|
          invoice.invoice_items.build(invoice_item.attributes)
        end
        invoice.save
      end
      raise ActiveRecord::Rollback unless all_saved
      all_saved
    end
  end

  def calculated
    %i(total cost vat).collect do |field|
      [field, invoice_items.to_a.sum(&field)]
    end.to_h
  end

  def recalculate
    self.total = invoice_items.to_a.sum(&:total) || 0
  end

  def to_s
    "#{title}(#{sequence_number}): #{total}"
  end

  def reminder_sent?
    payment_reminders.present?
  end

  def sent?
    sent_at.present?
  end

  def sent_state?
    state == 'sent'
  end

  def remindable?
    %w(sent reminded overdue).include?(state)
  end

  def recipients
    Person.where(id: recipient_ids.to_s.split(','))
  end

  private

  def set_self_in_nested
    invoice_items.each { |item| item.invoice = self }
  end

  def set_sequence_number
    self.sequence_number = [group_id, invoice_config.sequence_number].join('-')
  end

  def set_esr_number
    self.esr_number = sequence_number
  end

  def set_dates
    self.sent_at = Time.zone.today
    self.due_at = sent_at + invoice_config.due_days.days
  end

  def set_recipient_fields
    self.recipient_email = recipient.email
    self.recipient_address = build_recipient_address
  end

  def item_invalid?(attributes)
    !InvoiceItem.new(attributes.merge(invoice: self)).valid?
  end

  def increment_sequence_number
    invoice_config.increment!(:sequence_number)
  end

  def invoice_config
    group.invoice_config
  end

  def build_recipient_address
    [recipient.full_name,
     recipient.address,
     [recipient.zip_code, recipient.town].compact.join(' / '),
     recipient.country].compact.join("\n")
  end

end
