# frozen_string_literal: true

class GeminiApiService
  attr_accessor :client

  SYSTEM_INSTRUCTION = "You are a teacher grading a student's open-ended answer to a test question.
  Judge whether the answer correctly conveys the expected meaning, not whether
  it matches one exact phrasing — accept reasonable synonyms, paraphrasing,
  and minor differences in wording or grammar.

  Score the answer from 0 to 100:
  - 100 means fully correct and complete
  - 0 means entirely incorrect, irrelevant, or left blank
  - Use the full range in between for partially correct or incomplete answers

  Always respond using only the requested JSON structure — no extra text
  before or after it.
  "

  def initialize(model: 'gemini-3.1-flash-lite')
    @client = Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: ENV.fetch('GEMINI_API_KEY', nil)
      },
      options: { model: model, server_sent_events: true }
    )
  end

  def check_answer(question, answer)
    response = @client.generate_content(contents: contents(question, answer),
                                        system_instruction: system_instruction,
                                        generation_config: generation_config)
    response.dig('candidates', 0, 'content', 'parts', 0, 'text')
  end

  private

  def contents(question, answer)
    text = "Question: #{question}
            Student's answer: #{answer}
            Evaluate this answer."
    { role: 'user', parts: { text: text } }
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
          feedback: { type: 'string' }
        }
      }
    }
  end
end
