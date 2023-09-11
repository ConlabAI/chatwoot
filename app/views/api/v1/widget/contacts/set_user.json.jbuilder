json.id @contact.id
json.name @contact.anonymized_name
json.email @contact.anonymized_email
json.phone_number @contact.anonymized_phone_number
json.widget_auth_token @widget_auth_token if @widget_auth_token.present?
