# frozen_string_literal: true

class RailsTemplateGenerator
  attr_accessor :args

  def initialize(args)
    template_args = Struct.new(*args.keys, keyword_init: true)
    @args = template_args.new(**args)
    run_template(template)
  end

  private

  def run_template(template)
    system(template)
  end

  def template
    "rails new . -s -T --skip-git #{api_picked} #{action_mailer_picked} #{action_mailbox_picked}\
    #{action_text_picked} #{active_record_picked} #{active_job_picked} #{active_storage_picked}\
    #{action_cable_picked} #{asset_pipeline_picked} #{javascript_picked} #{hotwire_picked}\
    #{jbuilder_picked} #{bundle_picked} #{css_picked} --no-skip-rubocop --no-skip-brakeman -m ./template.rb"
  end

  def api_picked
    args.api ? "--api" : ""
  end

  def action_mailer_picked
    args.action_mailer ? "--no-skip-action-mailer" : "--skip-action-mailer"
  end

  def action_mailbox_picked
    args.action_mailbox ? "--no-skip-action-mailbox" : "--skip-action-mailbox"
  end

  def action_text_picked
    args.action_text ? "--no-skip-action-text" : "--skip-action-text"
  end

  def active_record_picked
    args.db == "none" ? "--skip-active-record" : "--database=#{db_picked} --no-skip-active-record"
  end

  def db_picked
    dbs = {
      mysql: "mysql",
      postgresql: "postgresql",
      sqlite3: "sqlite3",
      oracle: "oracle",
      sqlserver: "sqlserver",
      jdbcmysql: "jdbcmysql",
      jdbcsqlite3: "jdbcsqlite3",
      jdbcpostgresql: "jdbcpostgresql",
      jdbc: "jdbc"
    }

    dbs.fetch(args.db, "postgresql")
  end

  def active_job_picked
    args.active_job ? "--no-skip-active-job" : "--skip-active-job"
  end

  def active_storage_picked
    args.active_storage ? "--no-skip-active-storage" : "--skip-active-storage"
  end

  def action_cable_picked
    args.action_cable ? "--no-skip-action-cable" : "--skip-action-cable"
  end

  def asset_pipeline_picked
    if args.api || args.asset_pipeline == "none"
      "--skip-asset-pipeline"
    else
      "--asset-pipeline=#{pipeline_picked} --no-skip-asset-pipeline"
    end
  end

  def pipeline_picked
    pipelines = {
      sprockets: "sprockets",
      propshaft: "propshaft"
    }

    pipelines.fetch(args.asset_pipeline, "sprockets")
  end

  def javascript_picked
    args.api || (args.javascript == "none") ? "--skip-javascript" : "--javascript=#{js_picked} --no-skip-javascript"
  end

  def js_picked
    jss = {
      importmap: "importmap",
      webpack: "webpack",
      esbuild: "esbuild",
      bun: "bun",
      rollup: "rollup"
    }

    jss.fetch(args.javascript, "webpack")
  end

  def css_picked
    args.api || args.css_processor == "none" ? "" : "--css=#{css_processor_picked}"
  end

  def css_processor_picked
    css = {
      tailwind: "tailwind",
      bootstrap: "bootstrap",
      bulma: "bulma",
      postcss: "postcss",
      sass: "sass"
    }

    css.fetch(args.css_processor, "sass")
  end

  def hotwire_picked
    args.api && args.javascript != "none" && args.hotwire ? "--no-skip-hotwire" : "--skip-hotwire"
  end

  def bundle_picked
    args.bundle ? "--no-skip-bundle" : "--skip-bundle"
  end

  def jbuilder_picked
    args.jbuilder ? "--no-skip-jbuilder" : "--skip-jbuilder"
  end
end

# https://github.com/rails/rails/blob/7c68c5210cbc245d778daa7958cab73bc74f4669/railties/lib/rails/generators/app_base.rb#L200-L205
# OPTION_IMPLICATIONS = { # :nodoc:
#   skip_active_job:     [:skip_action_mailer, :skip_active_storage],
#   skip_active_record:  [:skip_active_storage],
#   skip_active_storage: [:skip_action_mailbox, :skip_action_text],
#   skip_javascript:     [:skip_hotwire],
# }
# api: [:skip_asset_pipeline, :skip_javascript]
RailsTemplateGenerator.new(
  {
    db: "postgresql",
    active_storage: "false".casecmp("true").zero?,
    action_mailbox: "true".casecmp("true").zero?,
    action_text: "false".casecmp("true").zero?,
    action_mailer: "true".casecmp("true").zero?,
    action_cable: "true".casecmp("true").zero?,
    jbuilder: true,
    bundle: true,
    api: "false".casecmp("true").zero?,
    active_job: "false".casecmp("true").zero?,
    asset_pipeline: "sprockets",
    javascript: "importmap",
    hotwire: "false".casecmp("true").zero?,
    css_processor: ""
  }
)
