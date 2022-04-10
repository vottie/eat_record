class EatRecordsController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user.id
    @eat_records = EatRecord.where(user_id: @user)
  end

  def show
    @eat_record = EatRecord.find(params[:id])
  end

  def new
    @eat_record = EatRecord.new
  end

  def create
    @eat_record = EatRecord.new(eat_record_params)
    @user = current_user.id
    @eat_record.user_id = @user
    if @eat_record.save
      redirect_to @eat_record
    else
      render :new, status: :unprocessable_entitiy
    end
  end

  def edit
    @eat_record = EatRecord.find(params[:id])
  end

  def update
    @eat_record = EatRecord.find(params[:id])

    if @eat_record.update(eat_record_params)
      redirect_to @eat_record
    else
      render :edit, status: :unporcessable_entity
    end
  end

  def destroy
    @eat_record = EatRecord.find(params[:id])
    @eat_record.destroy

    redirect_to root_path, status: :see_other
  end

  private
    def eat_record_params
      params.require(:eat_record).permit(:shop_name, :place_name, :usecase, :eat_with, :eat_date, :eat_time, :eat_menu, :article)
    end
end
