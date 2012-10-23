// Generated by CoffeeScript 1.3.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(function(require) {
    var $, Backbone, EditorSettings, GeneralSettings, GitHubSettings, GlViewSettings, KeyBindings, LocalStorage, Settings, _;
    $ = require('jquery');
    _ = require('underscore');
    Backbone = require('backbone');
    LocalStorage = require('localstorage');
    GeneralSettings = (function(_super) {

      __extends(GeneralSettings, _super);

      GeneralSettings.prototype.defaults = {
        maxRecentDisplay: 5,
        autoUpdateView: true
      };

      function GeneralSettings(options) {
        GeneralSettings.__super__.constructor.call(this, options);
        this.title = "General";
        this.set("title", this.title);
      }

      return GeneralSettings;

    })(Backbone.Model);
    GlViewSettings = (function(_super) {

      __extends(GlViewSettings, _super);

      GlViewSettings.prototype.defaults = {
        renderer: 'webgl',
        antialiasing: true,
        showGrid: true,
        showAxes: true,
        shadows: true
      };

      function GlViewSettings(options) {
        GlViewSettings.__super__.constructor.call(this, options);
        this.title = "3d view";
      }

      return GlViewSettings;

    })(Backbone.Model);
    EditorSettings = (function(_super) {

      __extends(EditorSettings, _super);

      EditorSettings.prototype.defaults = {
        startLine: 1,
        theme: "default"
      };

      function EditorSettings(options) {
        EditorSettings.__super__.constructor.call(this, options);
        this.title = "Code editor";
      }

      return EditorSettings;

    })(Backbone.Model);
    KeyBindings = (function(_super) {

      __extends(KeyBindings, _super);

      KeyBindings.prototype.defaults = {
        "undo": "CTRL+Z",
        "redo": "CTRL+Y"
      };

      function KeyBindings(options) {
        KeyBindings.__super__.constructor.call(this, options);
        this.title = "Key Bindings";
      }

      return KeyBindings;

    })(Backbone.Model);
    GitHubSettings = (function(_super) {

      __extends(GitHubSettings, _super);

      GitHubSettings.prototype.defaults = {
        configured: false
      };

      function GitHubSettings(options) {
        GitHubSettings.__super__.constructor.call(this, options);
        this.title = "GitHub Gist integration";
      }

      return GitHubSettings;

    })(Backbone.Model);
    Settings = (function(_super) {

      __extends(Settings, _super);

      Settings.prototype.localStorage = new Backbone.LocalStorage("Settings");

      function Settings(options) {
        this.clear = __bind(this.clear, this);

        this.save = __bind(this.save, this);

        this.init = __bind(this.init, this);
        Settings.__super__.constructor.call(this, options);
        this.bind("reset", this.onReset);
        this.init();
      }

      Settings.prototype.init = function() {
        this.add(new GeneralSettings());
        this.add(new GlViewSettings());
        this.add(new EditorSettings());
        this.add(new KeyBindings());
        return this.add(new GitHubSettings());
      };

      Settings.prototype.save = function() {
        return this.each(function(model) {
          return model.save();
        });
      };

      Settings.prototype.clear = function() {
        return this.each(function(model) {
          return model.destroy();
        });
      };

      Settings.prototype.onReset = function() {
        console.log("collection reset");
        console.log(this);
        return console.log("_____________");
      };

      return Settings;

    })(Backbone.Collection);
    return Settings;
  });

}).call(this);