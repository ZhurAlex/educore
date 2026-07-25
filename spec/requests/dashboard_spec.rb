require 'rails_helper'

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    it "redirects to sign in when not authenticated" do
      get root_path
      expect(response).to redirect_to(new_teacher_session_path)
    end

    it "succeeds when signed in" do
      teacher = create(:teacher)
      sign_in teacher

      get root_path
      expect(response).to have_http_status(:success)
    end
  end
end
