class RulesController < ApplicationController
  include Mixins::RuleSearch
  before_filter :load_rule
  skip_before_filter :load_rule, :only => [:new, :create, :index]
  before_filter :load_user, :only =>[:new, :create, :index]

  def index
    handle_rule_query
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @rules }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @subscriber }
    end
  end

  def new
    @rule = @user.rules.new
    @sample_subscriber = @user.subscribers.sample
    additional_attributes = "#{@user.subscribers.custom_attributes_counts.keys.join("=1;")}=1;"
    @sample_subscriber.additional_attributes = additional_attributes
    @interpolation_fields = InterpolationHelper.to_hash(@sample_subscriber, @user.id).keys
    @valid_selectors = Rule.valid_selectors(@user)
    @potential_channels = Channel.by_user(@user)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @rule }
    end
  end

  def edit
  end

  def create
    @rule = @user.rules.new(rule_params)
    respond_to do |format|
      if @rule.save
        format.html { redirect_to @rule, notice: 'Rule was successfully created.' }
        format.json { render json: @rule, status: :created, location: @rule }
      else
        format.html { render action: "new" }
        format.json { render json: @rule.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @rule.update_attributes(rule_params)
        format.html { redirect_to @rule, notice: 'Rule was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @rule.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @rule.destroy

    respond_to do |format|
      format.html { redirect_to rules_path }
      format.json { head :no_content }
    end
  end

  private

  def rule_params
    params.require(:rule)
          .permit(:name, :description, :priority, :rule_if,
                  :rule_then, :next_run_at, :system, :active,
                  :selection, :id)

  end

  def load_user
    authenticate_user!
    @user = current_user
  end

  def load_rule
    authenticate_user!
    @user = current_user
    begin
      @rule = @user.rules.find(params[:id])
      redirect_to(root_url, alert: 'Access Denied') unless @rule
    rescue => e
      redirect_to(root_url, alert: "Access Denied: #{e.message}. Please contact support.")
    end
  end


end
