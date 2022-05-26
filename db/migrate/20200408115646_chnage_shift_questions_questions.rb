class ChnageShiftQuestionsQuestions < ActiveRecord::Migration[5.2]
  def change
    FaqEntry.where(topic: 'shift_questions', position: 2).delete_all
    FaqEntry.create!(
        question: 'How do I register my interest in contracts?',
        answer: '<p> <span> From your staff profile view job vacancies in selected regions of the UK and simply click apply.  Do check your travel and if your skills match the requirements. </span> </p>',
        topic: 'shift_questions',
        position: 2)
    FaqEntry.create!(
        question: 'When do I get shift information?',
        answer: '<p> <span> Usually around 3-4 weeks before the start of each job we email you shift information, you reply with your chosen commitment and we then send reserved shifts to booking you in there and then. </span> </p>',
        topic: 'shift_questions',
        position: 2)
    FaqEntry.create!(
        question: 'Will my travel expenses be paid?',
        answer: '<p> <span> Majority of our contracts require self-travel plans. On the rare occasion we offer any form of travel expense this will be clearly stated on the job advert. </span> </p>',
        topic: 'shift_questions',
        position: 2)
    FaqEntry.create!(
        question: 'When will I know if I’m working?',
        answer: '<p> <span> Consider yourself confirmed and working from your shift offer or booking details.  We will require you to confirm the week of each contract . We then send out your final details to ensure you know everything that’s required and re-confirm your shifts. </span> </p>',
        topic: 'shift_questions',
        position: 2)
    FaqEntry.create!(
        question: 'What if I need to cancel a shift?',
        answer: '<p> <span> Then let us know ASAP, allow us time to offer the work to others.  We do record poor reliability which could affect future work with Flair People and our clients. </span> </p>',
        topic: 'shift_questions',
        position: 2)
    FaqEntry.create!(
        question: 'What Uniform should I wear?',
        answer: '<p> <span> Uniform information is targeted towards each contract you work.  Please review all information emails and notifications. Make sure you can comply with requirements.  </span> </p>',
        topic: 'shift_questions',
        position: 2)
    FaqEntry.create!(
        question: 'Do I have to sign in and out?',
        answer: '<p> <span> YES! Very important to ensure you get the correct wages without errors or delays. </span> </p>',
        topic: 'shift_questions',
        position: 2)
    FaqEntry.create!(
        question: 'How will I know who to meet?',
        answer: '<p> <span> Our Final details emails state who to meet, contact numbers and also have a pinpoint google map location of where to attend.  Any problems contact Flair HQ. </span> </p>',
        topic: 'shift_questions',
        position: 2)
    FaqEntry.create!(
        question: 'Employment breaks and Laws?',
        answer: '<p> <span> Legally for every 6hrs worked you are entitled to one uninterrupted break of 20 minutes rest for workers over 18 years. Flair ensures clients sign and accept this for each booking, please inform Flair HQ if ever you’re in a situation where this does not happen. </span> </p>',
        topic: 'shift_questions',
        position: 2)
    FaqEntry.create!(
        question: 'Do I receive a staff rating?',
        answer: '<p> <span> Yes! Clients and managers are encouraged to rate their teams, you can also rate them!  We encourage feedback to ensure quality of performance is maintained for everyone. We all want to work and be surrounded by good people so let’s all work together. </span> </p>',
        topic: 'shift_questions',
        position: 2)
  end
end
