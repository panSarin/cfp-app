class Staff::ProposalsController < Staff::ApplicationController
  include ProgramSupport

  before_action :require_proposal, only: [:show, :update_state, :update_track, :update_session_format, :finalize, :confirm_for_speaker]

  decorates_assigned :proposal, with: Staff::ProposalDecorator

  def index
    session[:prev_page] = {name: 'Proposals', path: event_staff_program_proposals_path}

    @proposals = @event.proposals
                     .includes(:event, :review_taggings, :proposal_taggings, :ratings,
                               {speakers: :user}).load
    @proposals = Staff::ProposalsDecorator.decorate(@proposals)
    @taggings_count = Tagging.count_by_tag(@event)
  end

  def show
    set_title(@proposal.title)
    current_user.notifications.mark_as_read_for_proposal(event_staff_proposal_url(@event, @proposal))

    @other_proposals = Staff::ProposalsDecorator.decorate(@proposal.other_speakers_proposals)
    @speakers = @proposal.speakers.decorate
    @rating = current_user.rating_for(@proposal)
  end

  def update_state
    if @proposal.finalized?
      authorize @proposal, :finalize?
    else
      authorize @proposal, :update_state?
    end

    @proposal.update_state(params[:new_state])

    respond_to do |format|
      format.html { redirect_to event_staff_program_proposals_path(@proposal.event) }
      format.js
    end
  end

  def update_track
    authorize @proposal

    @proposal.update(track_id: params[:track_id])

    render partial: '/shared/proposals/inline_track_edit'
  end

  def update_session_format
    authorize @proposal

    @proposal.update(session_format_id: params[:session_format_id])

    render partial: '/shared/proposals/inline_format_edit'
  end

  def selection
    session[:prev_page] = {name: 'Selection', path: selection_event_staff_program_proposals_path}

    @proposals = @event.proposals.working_program
                 .includes(:event, :review_taggings, :ratings,
                           {speakers: :user}).load
    @proposals = Staff::ProposalsDecorator.decorate(@proposals)
    @taggings_count = Tagging.count_by_tag(@event)
  end

  def session_counts
    track = params[:track_id]
    self.sticky_selected_track = track
    render json: {
        all_accepted_proposals: current_event.stats.all_accepted_proposals(sticky_selected_track),
        all_waitlisted_proposals: current_event.stats.all_waitlisted_proposals(sticky_selected_track)
      }
  end

  def finalize
    authorize @proposal, :finalize?

    @proposal.finalize
    Staff::ProposalMailer.send_email(@proposal).deliver_now
    redirect_to event_staff_program_proposal_path(@proposal.event, @proposal)
  end

  def finalize_remaining
    authorize Proposal, :finalize?

    @remaining = Proposal.soft_states
    @remaining.each do |prop|
      prop.finalize
    end
    errors = @remaining.map do |prop|
      Staff::ProposalMailer.send_email(prop).deliver_now unless prop.changed?
      prop.errors.full_messages.join(', ')
    end.compact!

    if errors.present?
      flash[:danger] = "There was a problem finalizing #{errors.size} proposals: \n#{errors.join("\n")}"
    else
      flash[:success] = "Successfully finalized remaining proposals."
    end
    redirect_to selection_event_staff_program_proposals_path
  end

  def confirm_for_speaker
    authorize @proposal, :finalize?

    if @proposal.confirm
      flash[:success] = "Proposal confirmed for #{@proposal.event.name}."
    else
      flash[:danger] = "There was a problem with confirmation: #{@proposal.errors.full_messages.join(', ')}"
    end

    redirect_to event_staff_program_proposal_path(slug: @proposal.event.slug, uuid: @proposal)
  end

end
