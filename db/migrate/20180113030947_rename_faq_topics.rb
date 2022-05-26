class RenameFaqTopics < ActiveRecord::Migration[5.1]
  def change
    FaqEntry.where(topic:    'recruitment').update_all(topic: 'joining_flair')
    FaqEntry.where(topic:          'other').update_all(topic: 'joining_flair')
    FaqEntry.where(topic:     'event_info').update_all(topic: 'pre_event')
    FaqEntry.where(topic:        'uniform').update_all(topic: 'event_days')
    FaqEntry.where(topic: 'camping_travel').update_all(topic: 'event_days')
    FaqEntry.where(topic:          'wages').update_all(topic: 'post_event')
  end
end
