tail -n +1 /Users/szaboale/Development/Flair/flair/app/views/staff_mailer/*.html.erb > all_staff_emails.html
sed -i '' 's/==>/<h1>==>/g' all_staff_emails.html
sed -i '' 's/<==/<==<\/h1>/g' all_staff_emails.html

tail -n +1 /Users/szaboale/Development/Flair/flair/app/views/public_mailer/*.html.erb > all_public_emails.html
sed -i '' 's/==>/<h1>==>/g' all_public_emails.html
sed -i '' 's/<==/<==<\/h1>/g' all_public_emails.html
