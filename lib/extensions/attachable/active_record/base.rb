module Extensions::Attachable::ActiveRecord::Base
  module ClassMethods
    # This function should be declared in model, to it have attachments.
    def has_many_attachments # rubocop:disable Style/PredicateName
      has_many :attachments, as: :attachable, inverse_of: :attachable,
                             dependent: :destroy, autosave: true

      define_method(:files=) do |files|
        files.each do |file|
          attachments.build.file_upload = file
        end
      end
    end

    def has_one_attachment # rubocop:disable Style/PredicateName
      include SingularInstanceMethods

      validates :attachments, length: { maximum: 1 }

      has_many :attachments, as: :attachable, inverse_of: :attachable,
                             dependent: :destroy, autosave: true
    end
  end

  module SingularInstanceMethods
    def attachment
      attachments[0]
    end

    def attachment=(attachment)
      attachments.clear
      attachments << attachment
    end

    def build_attachment(attributes = {})
      attachments.clear
      attachments.build(attributes)
    end

    def file=(file)
      build_attachment if !attachment || attachment.new_record?
      attachment.file_upload = file
    end
  end
end
