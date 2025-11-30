#  Copyright (c) 2025, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactAttrs
  class GroupControlBuilder < ControlBuilder
    def initiallize(form, group)
      super
      @group = group
    end

    def render
      safe_join([mandatory_contact_attrs,
        configurable_contact_attrs])
    end
  end
end
