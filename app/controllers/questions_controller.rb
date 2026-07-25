class QuestionsController < ApplicationController
  before_action :set_test, only: [:new, :create]
  before_action :set_question, only: [:edit, :update, :destroy]

  def new
    @question = @test.questions.new
    authorize @question
    2.times { @question.options.build }
  end

  def create
    @question = @test.questions.new(question_params)
    authorize @question

    if @question.save
      redirect_to @test, notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @question
    @question.options.build if @question.options.empty?
  end

  def update
    authorize @question

    if @question.update(question_params)
      redirect_to @question.test, notice: t(".success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @question
    test = @question.test
    @question.destroy
    redirect_to test, notice: t(".success")
  end

  private

  def set_test
    @test = Test.find(params[:test_id])
  end

  def set_question
    @question = Question.find(params[:id])
  end

  def question_params
    params.require(:question).permit(
      :body, :answer_type, :points, :correct_answer,
      options_attributes: [:id, :body, :correct, :_destroy]
    )
  end
end
