class ChnageJoiningFlairQuestions < ActiveRecord::Migration[5.2]
  def change
    FaqEntry.where(topic: 'joining_flair', position: 2).delete_all
    FaqEntry.create!(
        question: 'What experience do I need to join?',
        answer: '<p> <span> We seek people with a can do attitude, reliable and good working ethics. To have previous customer service experience is an asset or the drive to start. </span> </p>',
        topic: 'joining_flair',
        position: 2)
    FaqEntry.create!(
        question: 'What to expect from my video / telephone interview?',
        answer: '<p> <span> A 10-15 minute friendly interview, we are wanting to get to know you, reasons for joining Flair and to discuss your skills and interests. It’s also a chance for us to tell you what it’s like to work with us and answer your questions. </span> </p>',
        topic: 'joining_flair',
        position: 2)
    FaqEntry.create!(
        question: 'I worked for Flair years ago, how do I register my interest again?',
        answer: "<p> <span> Simply click 'Login' and enter the email address you last used. It will prompt you to create a password to connect you to your old profile. Due to GDPR rules there may be details we need to collect again, enter these and welcome back. </span> </p>",
        topic: 'joining_flair',
        position: 2)
    FaqEntry.create!(
        question: 'What happens after the interview?',
        answer: '<p> <span> If successful at your interview simply log into your staff profile and continue to build your job matching preferences. Also remember to finish adding any required admin like Right to Work ID and upload bank details. Next, select any job opportunities that fit around you and that match your skills. </span> </p>',
        topic: 'joining_flair',
        position: 2)
    FaqEntry.create!(
        question: 'What ID is required?',
        answer: '<p> <span> British passports and All EU passports are currently acceptable. Non-EU passports also require a working visa page or if you hold a residency card.  A second group of ID accepted is Full British born birth Certificates + National Insurance Evidence and any Photo ID.  All information is available in your staff profile to assist you to upload the correct information. Flair does carry out checks in accordance with UK Right to work requirements. </span> </p>',
        topic: 'joining_flair',
        position: 2)
  end
end
