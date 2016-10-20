# RailsAdmin config file. Generated on January 23, 2014 11:10
# See github.com/sferik/rails_admin for more informations

RailsAdmin.config do |config|


  ################  Global configuration  ################

  # Set the admin name here (optional second array element will appear in red). For example:
  config.main_app_name = ['Liveinspired', 'Admin']
  # or for a more dynamic name:
  # config.main_app_name = Proc.new { |controller| [Rails.application.engine_name.titleize, controller.params['action'].titleize] }

  # RailsAdmin may need a way to know who the current user is]
  config.current_user_method { current_user } # auto-generated

  config.authorize_with do |controller|
    unless current_user.try(:admin?)
      flash[:error] = 'You need to be admin to access this section'
      redirect_to '/'
    end 
  end

  # If you want to track changes on your models:
  # config.audit_with :history, 'User'

  # Or with a PaperTrail: (you need to install it first)
  # config.audit_with :paper_trail, 'User'

  # Display empty fields in show views:
  # config.compact_show_view = false

  # Number of default rows per-page:
  # config.default_items_per_page = 20

  # Exclude specific models (keep the others):
  # config.excluded_models = ['Action', 'ActionMessage', 'ActionNotice', 'AnnouncementsChannel', 'Channel', 'ChannelGroup', 'DeliveryNotice', 'IndividuallyScheduledMessagesChannel', 'Message', 'OnDemandMessagesChannel', 'OrderedMessagesChannel', 'PollMessage', 'RandomMessagesChannel', 'RelativelyScheduledMessagesChannel', 'ResponseMessage', 'ScheduledMessagesChannel', 'SecondaryMessagesChannel', 'SimpleMessage', 'Subscriber', 'SubscriberActivity', 'SubscriberResponse', 'Subscription', 'SwitchChannelAction', 'User']

  # Include specific models (exclude the others):
  # config.included_models = ['Action', 'ActionMessage', 'ActionNotice', 'AnnouncementsChannel', 'Channel', 'ChannelGroup', 'DeliveryNotice', 'IndividuallyScheduledMessagesChannel', 'Message', 'OnDemandMessagesChannel', 'OrderedMessagesChannel', 'PollMessage', 'RandomMessagesChannel', 'RelativelyScheduledMessagesChannel', 'ResponseMessage', 'ScheduledMessagesChannel', 'SecondaryMessagesChannel', 'SimpleMessage', 'Subscriber', 'SubscriberActivity', 'SubscriberResponse', 'Subscription', 'SwitchChannelAction', 'User']

  # Label methods for model instances:
  # config.label_methods << :description # Default is [:name, :title]


  ################  Model configuration  ################

  # Each model configuration can alternatively:
  #   - stay here in a `config.model 'ModelName' do ... end` block
  #   - go in the model definition file in a `rails_admin do ... end` block

  # This is your choice to make:
  #   - This initializer is loaded once at startup (modifications will show up when restarting the application) but all RailsAdmin configuration would stay in one place.
  #   - Models are reloaded at each request in development mode (when modified), which may smooth your RailsAdmin development workflow.


  # Now you probably need to tour the wiki a bit: https://github.com/sferik/rails_admin/wiki
  # Anyway, here is how RailsAdmin saw your application's models when you ran the initializer:



  ###  Action  ###

  # config.model 'Action' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your action.rb model definition

  #   # Found associations:

  #     configure :actionable, :polymorphic_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :type, :string 
  #     configure :as_text, :text 
  #     configure :deleted_at, :datetime 
  #     configure :actionable_id, :integer         # Hidden 
  #     configure :actionable_type, :string         # Hidden 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Message  ###

  # config.model 'Message' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your message.rb model definition

  #   # Found associations:

  #     configure :channel, :belongs_to_association 
  #     configure :delivery_notices, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 
  #     configure :action, :has_one_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :title, :text 
  #     configure :caption, :text 
  #     configure :type, :string 
  #     configure :channel_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :content_file_name, :string 
  #     configure :content_content_type, :string 
  #     configure :content_file_size, :integer 
  #     configure :content_updated_at, :datetime 
  #     configure :seq_no, :integer 
  #     configure :next_send_time, :datetime 
  #     configure :primary, :boolean 
  #     configure :reminder_message_text, :text 
  #     configure :reminder_delay, :integer 
  #     configure :repeat_reminder_message_text, :text 
  #     configure :repeat_reminder_delay, :integer 
  #     configure :number_of_repeat_reminders, :integer 
  #     configure :options, :serialized 
  #     configure :deleted_at, :datetime 
  #     configure :schedule, :text 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  SubscriberActivity  ###

  # config.model 'SubscriberActivity' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your subscriber_activity.rb model definition

  #   # Found associations:

  #     configure :subscriber, :belongs_to_association 
  #     configure :channel, :belongs_to_association 
  #     configure :message, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :subscriber_id, :integer         # Hidden 
  #     configure :channel_id, :integer         # Hidden 
  #     configure :message_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :origin, :string 
  #     configure :title, :text 
  #     configure :caption, :text 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :processed, :boolean 
  #     configure :deleted_at, :datetime 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Channel  ###

  # config.model 'Channel' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your channel.rb model definition

  #   # Found associations:

  #     configure :user, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 
  #     configure :messages, :has_many_association 
  #     configure :subscriptions, :has_many_association 
  #     configure :subscribers, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :description, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :keyword, :string 
  #     configure :tparty_keyword, :string 
  #     configure :next_send_time, :datetime 
  #     configure :schedule, :serialized 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :one_word, :string 
  #     configure :suffix, :string 
  #     configure :moderator_emails, :text 
  #     configure :real_time_update, :boolean 
  #     configure :deleted_at, :datetime 
  #     configure :relative_schedule, :boolean 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Channel  ###

  # config.model 'Channel' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your channel.rb model definition

  #   # Found associations:

  #     configure :user, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 
  #     configure :messages, :has_many_association 
  #     configure :subscriptions, :has_many_association 
  #     configure :subscribers, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :description, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :keyword, :string 
  #     configure :tparty_keyword, :string 
  #     configure :next_send_time, :datetime 
  #     configure :schedule, :serialized 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :one_word, :string 
  #     configure :suffix, :string 
  #     configure :moderator_emails, :text 
  #     configure :real_time_update, :boolean 
  #     configure :deleted_at, :datetime 
  #     configure :relative_schedule, :boolean 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  ChannelGroup  ###

  # config.model 'ChannelGroup' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your channel_group.rb model definition

  #   # Found associations:

  #     configure :user, :belongs_to_association 
  #     configure :default_channel, :belongs_to_association 
  #     configure :channels, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :description, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :tparty_keyword, :string 
  #     configure :keyword, :string 
  #     configure :default_channel_id, :integer         # Hidden 
  #     configure :moderator_emails, :text 
  #     configure :real_time_update, :boolean 
  #     configure :deleted_at, :datetime 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  SubscriberActivity  ###

  # config.model 'SubscriberActivity' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your subscriber_activity.rb model definition

  #   # Found associations:

  #     configure :subscriber, :belongs_to_association 
  #     configure :channel, :belongs_to_association 
  #     configure :message, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :subscriber_id, :integer         # Hidden 
  #     configure :channel_id, :integer         # Hidden 
  #     configure :message_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :origin, :string 
  #     configure :title, :text 
  #     configure :caption, :text 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :processed, :boolean 
  #     configure :deleted_at, :datetime 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Channel  ###

  # config.model 'Channel' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your channel.rb model definition

  #   # Found associations:

  #     configure :user, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 
  #     configure :messages, :has_many_association 
  #     configure :subscriptions, :has_many_association 
  #     configure :subscribers, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :description, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :keyword, :string 
  #     configure :tparty_keyword, :string 
  #     configure :next_send_time, :datetime 
  #     configure :schedule, :serialized 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :one_word, :string 
  #     configure :suffix, :string 
  #     configure :moderator_emails, :text 
  #     configure :real_time_update, :boolean 
  #     configure :deleted_at, :datetime 
  #     configure :relative_schedule, :boolean 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Message  ###

  # config.model 'Message' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your message.rb model definition

  #   # Found associations:

  #     configure :channel, :belongs_to_association 
  #     configure :delivery_notices, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 
  #     configure :action, :has_one_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :title, :text 
  #     configure :caption, :text 
  #     configure :type, :string 
  #     configure :channel_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :content_file_name, :string         # Hidden 
  #     configure :content_content_type, :string         # Hidden 
  #     configure :content_file_size, :integer         # Hidden 
  #     configure :content_updated_at, :datetime         # Hidden 
  #     configure :content, :paperclip 
  #     configure :seq_no, :integer 
  #     configure :next_send_time, :datetime 
  #     configure :primary, :boolean 
  #     configure :reminder_message_text, :text 
  #     configure :reminder_delay, :integer 
  #     configure :repeat_reminder_message_text, :text 
  #     configure :repeat_reminder_delay, :integer 
  #     configure :number_of_repeat_reminders, :integer 
  #     configure :options, :serialized 
  #     configure :deleted_at, :datetime 
  #     configure :schedule, :text 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Channel  ###

  # config.model 'Channel' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your channel.rb model definition

  #   # Found associations:

  #     configure :user, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 
  #     configure :messages, :has_many_association 
  #     configure :subscriptions, :has_many_association 
  #     configure :subscribers, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :description, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :keyword, :string 
  #     configure :tparty_keyword, :string 
  #     configure :next_send_time, :datetime 
  #     configure :schedule, :serialized 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :one_word, :string 
  #     configure :suffix, :string 
  #     configure :moderator_emails, :text 
  #     configure :real_time_update, :boolean 
  #     configure :deleted_at, :datetime 
  #     configure :relative_schedule, :boolean 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Channel  ###

  # config.model 'Channel' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your channel.rb model definition

  #   # Found associations:

  #     configure :user, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 
  #     configure :messages, :has_many_association 
  #     configure :subscriptions, :has_many_association 
  #     configure :subscribers, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :description, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :keyword, :string 
  #     configure :tparty_keyword, :string 
  #     configure :next_send_time, :datetime 
  #     configure :schedule, :serialized 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :one_word, :string 
  #     configure :suffix, :string 
  #     configure :moderator_emails, :text 
  #     configure :real_time_update, :boolean 
  #     configure :deleted_at, :datetime 
  #     configure :relative_schedule, :boolean 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Message  ###

  # config.model 'Message' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your message.rb model definition

  #   # Found associations:

  #     configure :channel, :belongs_to_association 
  #     configure :delivery_notices, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 
  #     configure :action, :has_one_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :title, :text 
  #     configure :caption, :text 
  #     configure :type, :string 
  #     configure :channel_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :content_file_name, :string 
  #     configure :content_content_type, :string 
  #     configure :content_file_size, :integer 
  #     configure :content_updated_at, :datetime 
  #     configure :seq_no, :integer 
  #     configure :next_send_time, :datetime 
  #     configure :primary, :boolean 
  #     configure :reminder_message_text, :text 
  #     configure :reminder_delay, :integer 
  #     configure :repeat_reminder_message_text, :text 
  #     configure :repeat_reminder_delay, :integer 
  #     configure :number_of_repeat_reminders, :integer 
  #     configure :options, :serialized 
  #     configure :deleted_at, :datetime 
  #     configure :schedule, :text 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Channel  ###

  # config.model 'Channel' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your channel.rb model definition

  #   # Found associations:

  #     configure :user, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 
  #     configure :messages, :has_many_association 
  #     configure :subscriptions, :has_many_association 
  #     configure :subscribers, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :description, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :keyword, :string 
  #     configure :tparty_keyword, :string 
  #     configure :next_send_time, :datetime 
  #     configure :schedule, :serialized 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :one_word, :string 
  #     configure :suffix, :string 
  #     configure :moderator_emails, :text 
  #     configure :real_time_update, :boolean 
  #     configure :deleted_at, :datetime 
  #     configure :relative_schedule, :boolean 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Channel  ###

  # config.model 'Channel' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your channel.rb model definition

  #   # Found associations:

  #     configure :user, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 
  #     configure :messages, :has_many_association 
  #     configure :subscriptions, :has_many_association 
  #     configure :subscribers, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :description, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :keyword, :string 
  #     configure :tparty_keyword, :string 
  #     configure :next_send_time, :datetime 
  #     configure :schedule, :serialized 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :one_word, :string 
  #     configure :suffix, :string 
  #     configure :moderator_emails, :text 
  #     configure :real_time_update, :boolean 
  #     configure :deleted_at, :datetime 
  #     configure :relative_schedule, :boolean 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Message  ###

  # config.model 'Message' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your message.rb model definition

  #   # Found associations:

  #     configure :channel, :belongs_to_association 
  #     configure :delivery_notices, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 
  #     configure :action, :has_one_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :title, :text 
  #     configure :caption, :text 
  #     configure :type, :string 
  #     configure :channel_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :content_file_name, :string 
  #     configure :content_content_type, :string 
  #     configure :content_file_size, :integer 
  #     configure :content_updated_at, :datetime 
  #     configure :seq_no, :integer 
  #     configure :next_send_time, :datetime 
  #     configure :primary, :boolean 
  #     configure :reminder_message_text, :text 
  #     configure :reminder_delay, :integer 
  #     configure :repeat_reminder_message_text, :text 
  #     configure :repeat_reminder_delay, :integer 
  #     configure :number_of_repeat_reminders, :integer 
  #     configure :options, :serialized 
  #     configure :deleted_at, :datetime 
  #     configure :schedule, :text 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Channel  ###

  # config.model 'Channel' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your channel.rb model definition

  #   # Found associations:

  #     configure :user, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 
  #     configure :messages, :has_many_association 
  #     configure :subscriptions, :has_many_association 
  #     configure :subscribers, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :description, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :keyword, :string 
  #     configure :tparty_keyword, :string 
  #     configure :next_send_time, :datetime 
  #     configure :schedule, :serialized 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :one_word, :string 
  #     configure :suffix, :string 
  #     configure :moderator_emails, :text 
  #     configure :real_time_update, :boolean 
  #     configure :deleted_at, :datetime 
  #     configure :relative_schedule, :boolean 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Channel  ###

  # config.model 'Channel' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your channel.rb model definition

  #   # Found associations:

  #     configure :user, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 
  #     configure :messages, :has_many_association 
  #     configure :subscriptions, :has_many_association 
  #     configure :subscribers, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :description, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :keyword, :string 
  #     configure :tparty_keyword, :string 
  #     configure :next_send_time, :datetime 
  #     configure :schedule, :serialized 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :one_word, :string 
  #     configure :suffix, :string 
  #     configure :moderator_emails, :text 
  #     configure :real_time_update, :boolean 
  #     configure :deleted_at, :datetime 
  #     configure :relative_schedule, :boolean 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Message  ###

  # config.model 'Message' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your message.rb model definition

  #   # Found associations:

  #     configure :channel, :belongs_to_association 
  #     configure :delivery_notices, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 
  #     configure :action, :has_one_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :title, :text 
  #     configure :caption, :text 
  #     configure :type, :string 
  #     configure :channel_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :content_file_name, :string 
  #     configure :content_content_type, :string 
  #     configure :content_file_size, :integer 
  #     configure :content_updated_at, :datetime 
  #     configure :seq_no, :integer 
  #     configure :next_send_time, :datetime 
  #     configure :primary, :boolean 
  #     configure :reminder_message_text, :text 
  #     configure :reminder_delay, :integer 
  #     configure :repeat_reminder_message_text, :text 
  #     configure :repeat_reminder_delay, :integer 
  #     configure :number_of_repeat_reminders, :integer 
  #     configure :options, :serialized 
  #     configure :deleted_at, :datetime 
  #     configure :schedule, :text 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Subscriber  ###

  # config.model 'Subscriber' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your subscriber.rb model definition

  #   # Found associations:

  #     configure :user, :belongs_to_association 
  #     configure :subscriptions, :has_many_association 
  #     configure :channels, :has_many_association 
  #     configure :delivery_notices, :has_many_association 
  #     configure :subscriber_responses, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :phone_number, :string 
  #     configure :remarks, :text 
  #     configure :last_msg_seq_no, :integer 
  #     configure :user_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :email, :string 
  #     configure :deleted_at, :datetime 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  SubscriberActivity  ###

  # config.model 'SubscriberActivity' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your subscriber_activity.rb model definition

  #   # Found associations:

  #     configure :subscriber, :belongs_to_association 
  #     configure :channel, :belongs_to_association 
  #     configure :message, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :subscriber_id, :integer         # Hidden 
  #     configure :channel_id, :integer         # Hidden 
  #     configure :message_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :origin, :string 
  #     configure :title, :text 
  #     configure :caption, :text 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :processed, :boolean 
  #     configure :deleted_at, :datetime 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  SubscriberActivity  ###

  # config.model 'SubscriberActivity' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your subscriber_activity.rb model definition

  #   # Found associations:

  #     configure :subscriber, :belongs_to_association 
  #     configure :channel, :belongs_to_association 
  #     configure :message, :belongs_to_association 
  #     configure :channel_group, :belongs_to_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :subscriber_id, :integer         # Hidden 
  #     configure :channel_id, :integer         # Hidden 
  #     configure :message_id, :integer         # Hidden 
  #     configure :type, :string 
  #     configure :origin, :string 
  #     configure :title, :text 
  #     configure :caption, :text 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :channel_group_id, :integer         # Hidden 
  #     configure :processed, :boolean 
  #     configure :deleted_at, :datetime 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Subscription  ###

  # config.model 'Subscription' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your subscription.rb model definition

  #   # Found associations:

  #     configure :channel, :belongs_to_association 
  #     configure :subscriber, :belongs_to_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :channel_id, :integer         # Hidden 
  #     configure :subscriber_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :deleted_at, :datetime 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  Action  ###

  # config.model 'Action' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your action.rb model definition

  #   # Found associations:

  #     configure :actionable, :polymorphic_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :type, :string 
  #     configure :as_text, :text 
  #     configure :deleted_at, :datetime 
  #     configure :actionable_id, :integer         # Hidden 
  #     configure :actionable_type, :string         # Hidden 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end


  ###  User  ###

  # config.model 'User' do

  #   # You can copy this to a 'rails_admin do ... end' block inside your user.rb model definition

  #   # Found associations:

  #     configure :channels, :has_many_association 
  #     configure :channel_groups, :has_many_association 
  #     configure :subscribers, :has_many_association 

  #   # Found columns:

  #     configure :id, :integer 
  #     configure :email, :string 
  #     configure :password, :password         # Hidden 
  #     configure :password_confirmation, :password         # Hidden 
  #     configure :reset_password_token, :string         # Hidden 
  #     configure :reset_password_sent_at, :datetime 
  #     configure :remember_created_at, :datetime 
  #     configure :sign_in_count, :integer 
  #     configure :current_sign_in_at, :datetime 
  #     configure :last_sign_in_at, :datetime 
  #     configure :current_sign_in_ip, :string 
  #     configure :last_sign_in_ip, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 

  #   # Cross-section configuration:

  #     # object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #     # label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #     # label_plural 'My models'      # Same, plural
  #     # weight 0                      # Navigation priority. Bigger is higher.
  #     # parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #     # navigation_label              # Sets dropdown entry's name in navigation. Only for parents!

  #   # Section specific configuration:

  #     list do
  #       # filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #       # items_per_page 100    # Override default_items_per_page
  #       # sort_by :id           # Sort column (default is primary key)
  #       # sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     end
  #     show do; end
  #     edit do; end
  #     export do; end
  #     # also see the create, update, modal and nested sections, which override edit in specific cases (resp. when creating, updating, modifying from another model in a popup modal or modifying from another model nested form)
  #     # you can override a cross-section field configuration in any section with the same syntax `configure :field_name do ... end`
  #     # using `field` instead of `configure` will exclude all other fields and force the ordering
  # end

end
