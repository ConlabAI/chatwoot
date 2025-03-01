json.auto_resolve_duration resource.auto_resolve_duration
json.created_at resource.created_at
if resource.custom_attributes.present?
  json.custom_attributes do
    json.plan_name resource.custom_attributes['plan_name']
    json.subscribed_quantity resource.custom_attributes['subscribed_quantity']
  end
end
json.domain @account.domain
json.features @account.enabled_features
json.id @account.id
json.locale @account.locale
json.name @account.name
json.anonymized @account.anonymized
json.support_email @account.support_email
json.status @account.status
json.cache_keys @account.cache_keys
