# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Course::Assessment::Answer::ProgrammingAutoGradingService do
  let(:instance) { create(:instance) }
  with_tenant(:instance) do
    with_active_job_queue_adapter(:test) do
      let(:answer) do
        arguments = *answer_traits
        options = arguments.extract_options!
        options[:question_traits] = question_traits
        options[:submission_traits] = submission_traits
        create(:course_assessment_answer_programming, :submitted, *arguments, options).answer
      end
      let(:question) { answer.question.actable }
      let(:question_traits) do
        [{
          template_package: true,
          template_package_deferred: false,
          test_cases: question_test_cases,
          maximum_grade: 3
        }]
      end
      let(:question_test_cases) do
        report = File.read(question_test_report_path)
        Course::Assessment::ProgrammingTestCaseReport.new(report).test_cases.map do |test_case|
          Course::Assessment::Question::ProgrammingTestCase.new(description: test_case.name,
                                                                identifier: test_case.identifier,
                                                                public: false)
        end
      end
      let(:question_test_report_path) do
        File.join(Rails.root, 'spec/fixtures/course/programming_single_test_suite_report.xml')
      end
      let(:submission_traits) { [{ auto_grade: false }] }
      let(:answer_traits) { [{ file_count: 1 }] }
      let(:grading) { create(:course_assessment_answer_auto_grading, answer: answer) }

      before do
        allow(Course::Assessment::ProgrammingEvaluationService).to \
          receive(:execute).and_wrap_original do |original, *args|
            result = original.call(*args)
            result.test_report = File.read(question_test_report_path)
            result
          end
      end

      describe '#grade' do
        subject { super().grade(grading) }
        let(:answer_contents) { 'test code ' + SecureRandom.hex }
        let(:answer_traits) { [{ file_contents: [answer_contents] }] }

        it 'creates a new package with the correct file contents' do
          expect(Course::Assessment::ProgrammingEvaluationService).to \
            receive(:execute).and_wrap_original do |method, *args|
            package = Course::Assessment::ProgrammingPackage.new(args[4])
            expect(package.submission_files.values).to contain_exactly(answer_contents)
            method.call(*args)
          end
          subject
        end

        it 'creates a Programming Auto Grading record' do
          subject
          expect(grading.actable).to be_a(Course::Assessment::Answer::ProgrammingAutoGrading)
        end

        context 'when the answer is correct' do
          let(:question_test_report_path) do
            File.join(Rails.root,
                      'spec/fixtures/course/programming_single_test_suite_report_pass.xml')
          end

          it 'marks the answer correct' do
            subject
            expect(answer.grade).to eq(question.maximum_grade)
            expect(answer).to be_correct
          end
        end

        context 'when the answer is wrong' do
          it 'marks the answer wrong' do
            subject
            expect(answer).not_to be_correct
          end

          it 'gives a grade proportional to the number of test cases' do
            subject
            test_case_count = answer.question.actable.test_cases.count
            expect(answer.grade).to eq(answer.question.maximum_grade / test_case_count)
          end
        end
      end
    end
  end
end
