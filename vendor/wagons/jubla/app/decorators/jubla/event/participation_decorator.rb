module Jubla::Event::ParticipationDecorator
  extend ActiveSupport::Concern
  
  included do
    alias_method_chain :qualification_link, :status
  end
  
  def qualification_link_with_status
    if event.qualification_possible?
      qualification_link_without_status
    else
      h.icon(qualified? ? :ok : :minus)
    end
  end
  
  
end