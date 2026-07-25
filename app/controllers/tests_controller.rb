class TestsController < ApplicationController
  before_action :set_test, only: [:show, :edit, :update, :destroy]

  def index
    authorize Test
    @tests = policy_scope(Test).order(:title)
  end

  def show
    authorize @test
    @questions = @test.questions.order(:id)
  end

  def new
    authorize Test
    @test = current_teacher.tests.new
  end

  def create
    authorize Test
    @test = current_teacher.tests.new(test_params)

    if @test.save
      redirect_to @test, notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @test
  end

  def update
    authorize @test

    if @test.update(test_params)
      redirect_to @test, notice: t(".success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @test
    @test.destroy
    redirect_to tests_path, notice: t(".success")
  end

  private

  def set_test
    @test = Test.find(params[:id])
  end

  def test_params
    params.require(:test).permit(:title, :locale)
  end
end
