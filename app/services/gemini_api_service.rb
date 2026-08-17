# frozen_string_literal: true

class GeminiApiService
  attr_accessor :client

  SYSTEM_INSTRUCTION = <<~PROMPT
    You are a teacher grading a student's open-ended answer to a test question.
    Judge whether the answer correctly conveys the expected meaning, not whether
    it matches one exact phrasing — accept reasonable synonyms, paraphrasing,
    and minor differences in wording or grammar.

    When a reference/expected answer is given, use it as the standard for
    correctness — the student's answer should convey the same key content,
    not match it word for word. When no reference answer is given, judge
    based on the question alone.

    Score the answer from 0 to 100:
    - 100 means fully correct and complete
    - 0 means entirely incorrect, irrelevant, or left blank
    - Use the full range in between for partially correct or incomplete answers

    Write the feedback in the same language as the question, regardless of
    what language the student's answer is written in — e.g. for a translation
    question, the feedback stays in the question's language even though the
    expected answer is in a different one.

    Always respond using only the requested JSON structure — no extra text
    before or after it.
  PROMPT

  class GradingError < StandardError; end

  def initialize(model: 'gemini-3.1-flash-lite')
    @client = Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: ENV.fetch('GEMINI_API_KEY', nil)
      },
      options: { model: model, server_sent_events: true }
    )
  end

  def check_answer(question_text, answer_text, reference_answer = nil)
    response = @client.generate_content({
                                          contents: contents(question_text, answer_text, reference_answer),
                                          system_instruction: system_instruction,
                                          generation_config: generation_config
                                        })
    text = response.dig('candidates', 0, 'content', 'parts', 0, 'text')

    raise GradingError, 'empty response from Gemini' if text.blank?

    result = JSON.parse(text)
    raise GradingError, 'response missing score' unless result.key?('score')

    raise GradingError, 'wrong score type' unless result['score'].is_a?(Integer)

    raise GradingError, 'wrong score value' unless (0..100).cover?(result['score'])

    result
  rescue Faraday::Error => e
    raise GradingError, "Gemini request failed: #{e.message}"
  rescue JSON::ParserError => e
    raise GradingError, "invalid JSON from Gemini: #{e.message}"
  end

  private

  def contents(question_text, answer_text, reference_answer)
    lines = ["Question: #{question_text}"]
    lines << "Reference/expected answer: #{reference_answer}" if reference_answer.present?
    lines << "Student's answer: #{answer_text}"
    lines << 'Evaluate this answer.'
    { role: 'user', parts: { text: lines.join("\n") } }
  end

  def system_instruction
    { role: 'user', parts: { text: SYSTEM_INSTRUCTION } }
  end

  def generation_config
    {
      response_mime_type: 'application/json',
      response_schema: {
        type: 'object',
        properties: {
          score: { type: 'integer' },
          feedback: {
            type: 'string',
            description: 'Feedback written in the same language as the question, ' \
                         'never in the language of the student\'s answer.'
          }
        }
      }
    }
  end
end
