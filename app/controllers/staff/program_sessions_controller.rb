class Staff::ProgramSessionsController < Staff::ApplicationController
  include ProgramSupport

  decorates_assigned :program_session, with: Staff::ProgramSessionDecorator
  decorates_assigned :sessions, with: Staff::ProgramSessionDecorator
  decorates_assigned :waitlisted_sessions, with: Staff::ProgramSessionDecorator

  def index
    @sessions = current_event.program_sessions.active_or_inactive
    @waitlisted_sessions = current_event.program_sessions.waitlisted

    session[:prev_page] = { name: 'Program', path: event_staff_program_sessions_path(current_event) }

    respond_to do |format|
      format.html { render }
      format.json { render_json(current_event.program_sessions.active, filename: json_filename)}
    end
  end

  def show
    @program_session = current_event.program_sessions.find(params[:id])
    @speakers = @program_session.speakers
  end

  def edit
    @program_session = current_event.program_sessions.find(params[:id])
    authorize @program_session
  end

  def update
    @program_session = current_event.program_sessions.find(params[:id])
    authorize @program_session
    if @program_session.update(program_session_params)
      flash[:success] = "#{@program_session.title} was successfully updated."
      redirect_to event_staff_program_session_path(current_event, @program_session)
    else
      flash[:danger] = "There was a problem updating this program session."
      render :edit
    end

  end

  def new
    @program_session = current_event.program_sessions.build
    authorize @program_session
    @speaker = @program_session.speakers.build
  end

  def create
    @program_session = current_event.program_sessions.build(program_session_params)
    authorize @program_session
    @program_session.state = ProgramSession::INACTIVE
    @program_session.speakers.each { |speaker| speaker.event_id = current_event.id }
    if @program_session.save
      redirect_to event_staff_program_session_path(current_event,  @program_session)
      flash[:info] = "Program session was successfully created."
    else
      flash[:danger] = "Program session was unable to be saved: #{@program_session.errors.full_messages.to_sentence}"
      render :new
    end
  end

  def destroy
    @program_session = current_event.program_sessions.find(params[:id])
    authorize @program_session
    @program_session.destroy
    redirect_to event_staff_program_sessions_path(event)
    flash[:info] = "Program session was successfully deleted."
  end

  def speaker_emails
    emails = current_event.program_sessions.where(id: params[:session_ids]).emails
    respond_to do |format|
      format.json { render json: {emails: emails} }
    end
  end

  private

  def program_session_params
    params.require(:program_session).permit(:id, :session_format_id, :track_id, :title,
                                            :abstract, :state, :video_url, :slides_url,
                                            speakers_attributes: [:id, :bio, :speaker_name, :speaker_email])
  end

  def json_filename
    "#{current_event.slug}-program-#{DateTime.current.to_s(:db_just_date)}.json"
  end
end
