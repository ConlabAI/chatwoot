json.additional_attributes resource.additional_attributes
json.availability_status resource.availability_status
json.email resource.anonymized_email
json.id resource.id
json.name resource.anonymized_name
json.phone_number resource.anonymized_phone_number
json.identifier resource.anonymized_identifier
json.thumbnail resource.anonymized_avatar_url
json.custom_attributes resource.custom_attributes
json.conversations_count resource.conversations_count if resource[:conversations_count].present?
json.last_activity_at resource.last_activity_at.to_i if resource[:last_activity_at].present?
json.created_at resource.created_at.to_i if resource[:created_at].present?
# we only want to output contact inbox when its /contacts endpoints
if defined?(with_contact_inboxes) && with_contact_inboxes.present?
  json.contact_inboxes do
    json.array! resource.contact_inboxes do |contact_inbox|
      json.partial! 'api/v1/models/contact_inbox', formats: [:json], resource: contact_inbox
    end
  end
end
