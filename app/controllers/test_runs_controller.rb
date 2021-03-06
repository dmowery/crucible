class TestRunsController < ApplicationController
  respond_to :json

  def show
    test_run = TestRun.includes(:test_results).find(params[:id])
    test_run['test_results'] = test_run.test_results
    render json: {test_run: test_run}
  end

  def create
    server = Server.find(params[:server_id])
    run = TestRun.new({server_id: server.id.to_s, date: Time.now, supported_only: (params[:supported_only]=='true'), fhir_version: server.fhir_sequence.downcase})
    tests = params[:test_ids].map {|i| Test.find(i)}

    run.add_tests(tests)
    RunTestsJob.perform_later(run.id.to_s)

    render json: { test_run: run }
  end

  def cancel
    run = TestRun.find(params[:test_run_id])

    if run.status == 'pending' or run.status == 'running'
      run.status = 'cancelled'
      run.save
    end

    render json: { test_run: run }
  end
end
