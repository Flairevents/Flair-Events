class AddWagesQuestions < ActiveRecord::Migration[5.2]
  def change
    FaqEntry.where(topic: 'wages', position: 2).delete_all
    FaqEntry.create!(
        question: 'When do I get paid? ',
        answer: '<p> <span> Weekly –Our working week is Monday to Sunday, and you receive payment the following Friday direct into your bank account. </span> </p>',
        topic: 'wages',
        position: 2)
    FaqEntry.create!(
        question: 'Payslips.',
        answer: "<p> <span> We send payslips at least 48 hrs before your BACS payment, to enable time for enquiries. If in any doubt email us stating clearly the contract, location of work, start and finish times etc. Please take a moment to consider the contract's scheduled working times, your hourly rate and most importantly your personal tax situation which would all effect your personal net pay. </span> </p>",
        topic: 'wages',
        position: 2)
    FaqEntry.create!(
        question: 'You have the wrong tax code?',
        answer: "<p> <span> When commencing work for any employer, a starter declaration form is requested to confirm your employment status. Flair operates a W1/M1 non-accumulative system and our software will tax your earnings based on us being your 'only' or 'second' employer. Once you have been physically paid by Flair, we send your details to HMRC via RTI uploads. If your initial tax code is deemed incorrect, HMRC will provide an alternative tax code resulting in a rebate or increased charges. </span><br><span> We have no control over your tax codes, fill in your starter declaration correctly and give the system time to adjust once RTI has been sent as required. </span> </p>",
        topic: 'wages',
        position: 2)
    FaqEntry.create!(
        question: 'Am I entitled to holiday pay?',
        answer: '<p> <span> 100% YES at a rate of 12.07% on the hour!  All our contracts are advertised with your hourly base rate and Holiday Pay breakdown.  We pay as per your payslip to ensure you get this straight away. </span> </p>',
        topic: 'wages',
        position: 2)
    FaqEntry.create!(
        question: 'I did not receive my wage?',
        answer: '<p> <span> First check your profile and that your bank details are correct.  Email us straight away if there is a problem so we can investigate, clearly state in the subject box ‘wage enquiry’.  </span> </p>',
        topic: 'wages',
        position: 2)
    FaqEntry.create!(
        question: "I'm self-employed, how does this work with pay?",
        answer: '<p> <span> Flair uses PAYE for all employees, the jobs we offer do not meet HMRC classifications for self-employed status. All records available to enable you to file end of year tax returns to obtain any tax back you may have paid via Flair. </span> </p>',
        topic: 'wages',
        position: 2)
  end
end
