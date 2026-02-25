class UserPreference < ApplicationRecord
  belongs_to :user

  after_initialize :set_defaults

  def get_preference(key)
    return nil unless preferences.is_a?(Hash)
    preferences[key.to_s]
  end

  def set_preference(key, value)
    self.preferences ||= {}
    self.preferences[key.to_s] = value
  end

  def get_widget(widget_id)
    return nil unless widgets.is_a?(Hash)
    widgets[widget_id.to_s]
  end

  def set_widget(widget_id, config)
    self.widgets ||= {}
    self.widgets[widget_id.to_s] = config
  end

  private

  def set_defaults
    self.preferences ||= {}
    self.widgets ||= {}
  end
end
