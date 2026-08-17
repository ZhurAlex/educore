# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeminiApiService do
  subject(:service) { described_class.new }

  let(:client) { instance_double(Gemini::Controllers::Client) }

  # Stubbed before `service` is built: GeminiApiService#initialize calls the
  # real Gemini.new, which resolves Google Auth credentials — that must never
  # run in tests, regardless of what's (or isn't) in GEMINI_API_KEY locally.
  before { allow(Gemini).to receive(:new).and_return(client) }

  def gemini_response(text)
    { 'candidates' => [{ 'content' => { 'parts' => [{ 'text' => text }] } }] }
  end

  describe '#check_answer' do
    context 'when Gemini returns a valid score and feedback' do
      it 'returns the parsed result' do
        allow(client).to receive(:generate_content)
          .and_return(gemini_response({ score: 80, feedback: 'Good job' }.to_json))

        result = service.check_answer('2 + 2?', '4')

        expect(result).to eq('score' => 80, 'feedback' => 'Good job')
      end
    end

    context 'when the response has no text (blocked/empty candidates)' do
      it 'raises GradingError' do
        allow(client).to receive(:generate_content).and_return({ 'candidates' => [] })

        expect { service.check_answer('2 + 2?', '4') }
          .to raise_error(GeminiApiService::GradingError, /empty response/)
      end
    end

    context 'when the response text is not valid JSON' do
      it 'raises GradingError' do
        allow(client).to receive(:generate_content).and_return(gemini_response('not json'))

        expect { service.check_answer('2 + 2?', '4') }
          .to raise_error(GeminiApiService::GradingError, /invalid JSON/)
      end
    end

    context 'when the parsed response is missing a score' do
      it 'raises GradingError' do
        allow(client).to receive(:generate_content)
          .and_return(gemini_response({ feedback: 'Good job' }.to_json))

        expect { service.check_answer('2 + 2?', '4') }
          .to raise_error(GeminiApiService::GradingError, /missing score/)
      end
    end

    context 'when the request fails (network/HTTP error)' do
      it 'raises GradingError' do
        allow(client).to receive(:generate_content).and_raise(Faraday::TimeoutError, 'timed out')

        expect { service.check_answer('2 + 2?', '4') }
          .to raise_error(GeminiApiService::GradingError, /Gemini request failed/)
      end
    end
  end
end
