"use strict";

//$ = jQuery;

var Training = Training || {};

/**
 * Class that manages the whole test suite
 */
Training.TestModule = (function(){
  /**
   * @constructor
   *
   * The constructor accepts a DOM object with a collection of test questions in
   * it. The test questions are DIVs of class 'fl-training__step'.
   *
   * @param   {obj}   The DOM object with the collection of test steps
   * @returns  {obj}   The object
   */
  function TestModule(domElement,moduleName,status,index) {
    this.moduleName = moduleName || '';
    this.training = domElement;
    this.steps = this.training.find('.fl-training__step');
    this.evals = new Training.Evaluations();
    this.index = index || 0;
    this.wrongs = [];
    this.show(this.index);
    if(status!="completed") {
      this.addNavButtons(status);
      this.hideAnswers(true);
      this.activateSortable();
      this.activateSumTotals();
    }
  }

  /**
   * Loads audio files for playing
   */
  TestModule.prototype.loadAudios = function() {
    if($(".audiomedia").length>=3) return false;
    $('body').append(
      '<audio id="fl-training__audio--correct" class="audiomedia">\n'+
      '  <source src="/assets/correct.ogg" type="audio/ogg">\n'+
      '  <source src="/assets/correct.mp3" type="audio/mpeg">\n'+
      '  Your browser does not support the audio element.\n'+
      '</audio>\n'+
      '<audio id="fl-training__audio--success" class="audiomedia">\n'+
      '  <source src="/assets/success.ogg" type="audio/ogg">\n'+
      '  <source src="/assets/success.mp3" type="audio/mpeg">\n'+
      '  Your browser does not support the audio element.\n'+
      '</audio>\n'+
      '<audio id="fl-training__audio--wrong" class="audiomedia">\n'+
      '  <source src="/assets/wrong.ogg" type="audio/ogg">\n'+
      '  <source src="/assets/wrong.mp3" type="audio/mpeg">\n'+
      '  Your browser does not support the audio element.\n'+
      '</audio>\n'
    );
    return true;
  };

  TestModule.prototype.show = function(index) {
    this.index = index;
    this.hideAll();
    if (this.index >= this.steps.length) this.index = 0;
    if (this.index < 0) this.index = this.steps.length - 1;
    this.currentStep = $(this.steps[this.index]);
    this.currentStep.addClass('active');
    this.slideView();
    $('body').trigger('layoutChange');
  };

  TestModule.prototype.showNext = function() {
    this.show(this.index + 1);
    this.updateProgress(this.moduleName, this.index);
    this.ifFinalStep(function(){
      this.playAudio('success');
      this.completeTrainingModule(this.moduleName);
      setTabCheckMark("tabs-training","tab_training_" + this.moduleName,true);
    }.bind(this));
  };

  TestModule.prototype.showPrev = function() {
    this.show(this.index - 1);
  };

  /**
   * Moves the question into view
   */
  TestModule.prototype.slideView = function() {
    var navbarHeight = $(".navbar").height();
    var scrollPoint = $("#training").position().top - navbarHeight;
    $("html, body").animate({scrollTop:scrollPoint}, '500', 'swing');
  };

  TestModule.prototype.addNavButtons = function(status) {
    this.steps.each(function(index, step) {
      if (index === 0) {
        $(step).append(
        '<div class="pt1 text-right fl-training__nav">\n'+
        '  <a class="btn btn-default fl-training__nav__next">Start</a>\n'+
        '</div>\n');
      } else if ($(step).hasClass('fl-training__step--no-response-required')) {
        $(step).append(
        '<div class="pt1 text-right fl-training__nav">\n'+
        '  <!-- <a class="btn fl-training__nav__prev">Previous</a> -->\n'+
        '  <a class="btn btn-default fl-training__nav__next">Next</a>\n'+
        '</div>\n');
      } else if (index === this.steps.length - 1) {
        $(step).append(
        '<div class="pt1 fl-btn-group fl-training__nav">\n'+
        '  <!-- <a class="btn fl-training__nav__prev">Previous</a> -->\n'+
        '  <a class="btn btn-default fl-training__nav__finish" href="#tab-training-intro">Finish</a>\n'+
        '  <input type="submit" value="Submit" class="btn btn-default fl-training__nav__submit hidden">\n'+
        '</div>\n');
      } else {
        $(step).append(
        '<div class="pt1 fl-btn-group fl-training__nav">\n'+
        '  <!-- <a class="btn fl-training__nav__prev">Previous</a> -->\n'+
        '  <a class="btn btn-default fl-training__nav__check">Check Answers</a>\n'+
        '</div>\n');
      }
    }.bind(this));
    this.training.find('.fl-training__nav__next').click(function() {
      this.showNext();
    }.bind(this));
    /*
    this.training.find('.fl-training__nav__prev').click(function() {
      this.showPrev();
    }.bind(this));
    */
    this.training.find('.fl-training__nav__check').click(function() {
      this.checkAnswers();
    }.bind(this));
    this.training.find('.fl-training__step--auto-fill .fl-training__nav__check').click(function() {
      this.fillAnswers();
    }.bind(this));
    this.training.find('.fl-training__instant-response').change(function() {
      this.checkAnswers(false);
    }.bind(this));
    this.training.find('.fl-training__nav__finish').click(function() {
      $('a[role="tab"][href="#tab-training-intro"]').tab('show');
    });
  };

  /**
   * Clears all green correct checkmarks or red incorrect 'x's
   */
  TestModule.prototype.hideAnswers = function(all) {
    if(all) {
      this.steps.find('.fl-training__notice').removeClass('active');
      return true;
    }
    this.currentStep.find('.fl-training__notice').removeClass('active');
  };

  TestModule.prototype.hideAll = function() {
    this.steps.removeClass('active');
  };

  TestModule.prototype.checkAnswers = function(validate) {
    validate = validate || true;
    var that = this;
    var allFieldsFilledOut = true;
    this.wrongs = [];
    /**
     * Activates either a green check mark or a red 'x' indicating a correct or
     * incorrect answer.
     * If the anser if incorrect then this answer is pushed into a 'wrongs'
     * array.
     */
    var checkAndShowConditionals = function() {
      var conditionals = $(that.currentStep).find('.fl-training__notice[data-flair-training-eval-function]');
      if (conditionals.length > 0) {
        conditionals.each(function(index, conditional) {
          var evalFunction = $(conditional).data('flair-training-eval-function');
          var evalArg = $(conditional).data('flair-training-eval-arg');
          var evalArg2 = $(conditional).data('flair-training-eval-arg-2');
          var result = this.evals[evalFunction](this.currentStep, evalArg, evalArg2);
          if (String(result) == String($(conditional).data('flair-training-condition'))) {
            $(conditional).addClass('active');
            if ($(conditional).hasClass('fl-training__notice--wrong')) this.wrongs.push(conditional);
          } else {
            $(conditional).removeClass('active');
          }
        }.bind(that));
      }
    };
    var checkFormValidationAndShowMessages = function() {
      if($(that.currentStep).find(':invalid').length > 0) {
        $(that.training).find(':submit').click();
        return false;
      }
      return true;
    };

    this.hideAnswers();
    // Clear all colored icons indicating if the answer is correct or not

    checkAndShowConditionals();
    // By this time we should have some colored icons indicating if the answer is correct or not

    if (validate) allFieldsFilledOut = checkFormValidationAndShowMessages();

    if (allFieldsFilledOut && this.wrongs.length === 0) {
      var showUnconditionalCorrects = function() {
        that.currentStep.find('.fl-training__notice--correct:not([data-flair-training-eval-function])').addClass('active');
      };

      showUnconditionalCorrects();

      this.playAudio('correct');
      if (validate) {
        this.setNextButton(this.currentStep.find('.fl-training__nav__check'));
        this.currentStep.addClass('answered');
        this.detectAnswerChanges();
      }
      return true;
    } else {
      this.playAudio('wrong');
      this.currentStep.find('.fl-training__notice--wrong:not([data-flair-training-eval-function])').addClass('active');
      return false;
    }
  };

  TestModule.prototype.setNextButton = function(domElement) {
    domElement.removeClass('.fl-training__nav__check')
      .addClass('fl-training__nav__next')
      .off() // Remove all event handlers
      .click(function() { this.showNext() }.bind(this))
      .html('Next');
  };

  TestModule.prototype.setCheckButton = function(domElement) {
    domElement.removeClass('.fl-training__nav__next')
      .addClass('fl-training__nav__check')
      .off()
      .click(function() { this.checkAnswers() }.bind(this))
      .html('Check Answers');
  };

  TestModule.prototype.detectAnswerChanges = function() {
    var inputs = this.currentStep.find('input').length;
    var selects = this.currentStep.find('select').length;
    var detectableElements = (inputs > selects) ? "input" : "select";
    this.currentStep.find(detectableElements).change(function() {
      this.currentStep.removeClass("answered");
      this.setCheckButton(this.currentStep.find('.fl-training__nav__next'));
    }.bind(this));
  };

  TestModule.prototype.fillAnswers = function() {
    $(this.training).find(':checkbox[data-auto-fill]').each(function(index, element) {
      if ($(element).attr('data-auto-fill') == 'yes') {
        $(element).prop("checked", true)
      }
    });
  };

  TestModule.prototype.activateSortable = function() {
    var matchGroup = 0;
    $(this.training).find('.fl-match').each(function(){
      matchGroup++;
      $(this).find('.fl-match__target__container').each(function(){
        var sortable = Sortable.create(this, {
          animation: 150,
          group: matchGroup
        });
      });
    });
    $(this.training).find('.fl-priority').each(function(i,elemt){
      Sortable.create(elemt,{
        animation:400,
        forceFallback: false,
        group:"priority",
        ghostClass: 'ghost',
        onUpdate: function(evt) {
          $(evt.item).addClass("moved");
        }
      });
    });
  };

  TestModule.prototype.activateSumTotals = function() {
    $(this.steps).find('.fl-training__checkbox-count').each(function(index, element) {
      var that = this;
      var checkboxName = $(element).attr('data-flair-training-count-checkbox-target');
      $(this.steps).find(':checkbox[name='+checkboxName+']').click(function() {
        $(element).text($(this.steps).find(':checkbox:checked[name='+checkboxName+']').length);
      }.bind(that));
    }.bind(this));
  };

  TestModule.prototype.ifFinalStep = function(cb) {
    if (this.index != this.steps.length - 1) return false;
    if(typeof cb === "function") cb();
  };

  TestModule.prototype.playAudio = function(type) {
    type = type || "wrong";
    // Make sure the audio element exists then play it
    if($('#fl-training__audio--' + type).length > 0) $('#fl-training__audio--' + type)[0].play();
  };

  // Add a routine to update progress (index) each time a question is skipped to
  TestModule.prototype.updateProgress = function(module, index) {
    if(module==null || index == null) return false;
      $.ajax({
          url: '/staff/update_training_module_progress',
          data: { module : module, index: index },
          type: 'POST',
          error: function(request, errorType, errorMessage) {
              console.error("error: " + errorMessage)
          }
      });
  };

  TestModule.prototype.completeTrainingModule = function(module) {
    if(module===null || module==="undefined") return false;
    $.ajax({
      url: '/staff/mark_training_module_complete',
      data: { module : module },
      type: 'POST',
      error: function(request, errorType, errorMessage) {
        console.error("error: " + errorMessage)
      }
    });
  };

  return TestModule;
})();

Training.Evaluations = (function() {
  /**
   * @constructor
   *
   * The constructor accepts a DOM object with a collection of test questions in
   * it. The test questions are DIVs of class 'fl-training__step'.
   *
   * @param   {obj}   The DOM object with the collection of test steps
   * @returns  {obj}   The object
   */
  function Evaluations() {
  }

  Evaluations.prototype.averageFormSelectValues = function(step) {
    var mapped = $(step).find('select').get().map(function(select) {
      var val = parseInt($(select).find('option:selected').attr('value'));
      return val ? val : 0;
    });
    var sum = mapped.reduce(function(a, b) { return (a + b) });
    var avgCeil = Math.ceil(sum / mapped.length);
    return avgCeil;
  };

  /**
   * Checks the 'score' of the top <count> items in the ordered list
   * The idea is that the top scores in the ordered list ought to reflect
   * higher 'values'. The values are represented by scores bound to the
   * orderable responses.
   *
   * So, we give 'money' or 'fame' or other qualities like that with low
   * 'values'. 'fulfillment', 'enjoyment', etc get higher 'values'.
   *
   * Validator pulls <count> items from the top of the list and adds them up.
   * A jerk who orders money and fame highest will get a lower score then the
   * angel who puts 'sense of purpose' at the top.
   */
  Evaluations.prototype.checkPriorityScore = function(step,count,priority) {
    var items = $(step).find("li");
    count = count || $(items).length;
    var score = 0;
    for(var c=0; c<count; c++) {
      score += parseInt($(items[c]).data("value"));
    }
    score = (score/count);
    return (score>=parseInt(priority));
  };

  Evaluations.prototype.checkMismatch = function(step) {
    var mismatches = [];
    $(step).find('.fl-match__target').each(function(){
      var target = $(this).find('.fl-match__target__title').attr('data-flair-training-match');
      var source = $(this).find('.fl-match__source').attr('data-flair-training-match');
      if( target != source) {
        mismatches.push($(this).find('.fl-match__target__title').text());
      }
    });

    return (mismatches.length > 0);
  };

  Evaluations.prototype.numberOfSelectedCheckboxes = function(step) {
    var selectedCheckbox = $(step).find(':checkbox:checked');
    return selectedCheckbox.length;
  };

  Evaluations.prototype.numberOfSelectedCheckboxesNot = function(step, num) {
    var selectedCheckbox = $(step).find(':checkbox:checked');
    return parseInt(num) != selectedCheckbox.length;
  };

  Evaluations.prototype.numberOfSelectedCheckboxesLess = function(step, num) {
    var selectedCheckbox = $(step).find(':checkbox:checked');
    return parseInt(num) > selectedCheckbox.length;
  };

  Evaluations.prototype.numberOfSelectedCheckboxesGreater = function(step, num) {
    var selectedCheckbox = $(step).find(':checkbox:checked');
    return parseInt(num) < selectedCheckbox.length;
  };

  Evaluations.prototype.professionalAttributes = function(step) {
    var selectedCheckbox = $(step).find(':checkbox:checked');
    if (selectedCheckbox.length <= 4) {
      return 4;
    } else if (selectedCheckbox.length <= 11) {
      return 11;
    } else if (selectedCheckbox.length <= 21) {
      return 21;
    } else {
      return 30;
    }
  };

  Evaluations.prototype.radioValue = function(step, radioName) {
    var selectedRadio = radioName ? $(step).find(':radio[name="'+radioName+'"]:checked').first() : $(step).find(':radio:checked').first();
    if (selectedRadio) {
      return selectedRadio.attr('value');
    }
  };

  Evaluations.prototype.checkboxValue = function(step, checkboxName) {
    var selectedCheckbox = checkboxName ? $(step).find(':checkbox[name="'+checkboxName+'"]:checked').first() : $(step).find(':checkbox:checked').first();
    if (selectedCheckbox) {
      return selectedCheckbox.attr('value');
    }
  };

  Evaluations.prototype.selectValue = function(step, selectName) {
    var selectedSelect = selectName ? $(step).find('select[name="'+selectName+'"] :selected').first() : $(step).find('option :selected').first();
    if (selectedSelect) {
      return selectedSelect.attr('value');
    }
  };

  Evaluations.prototype.checkboxChecked = function(step, checkboxValue) {
    var selectedCheckbox = checkboxValue ? $(step).find(':checkbox[value="'+checkboxValue+'"]:checked').first() : $(step).find(':checkbox:checked').first();
    return selectedCheckbox.length > 0;
  };

  Evaluations.prototype.checkboxCheckedMulti = function(step,checkedArray) {
    var correctResponses = checkedArray.split(",");
    var selectedCheckboxes = $(step).find(':checkbox:checked');
    if(correctResponses.length!=selectedCheckboxes.length) return false;
    for(var c=0; c<selectedCheckboxes.length; c++) {
      var selectedCheckboxValue = $(selectedCheckboxes[c]).attr('value');
      if(correctResponses.indexOf(selectedCheckboxValue)<0) return false;
    }
    return true;
  };

  Evaluations.prototype.compareBySelectors = function(step, selector1, selector2) {
    var val1 = $(step).find(selector1).text();
    var val2 = $(step).find(selector2).text();
    return val1 > val2;
  };

  Evaluations.prototype.checkDragMatch = function(step,countLimit) {
    var peopleArray = $(step).find("ul.ageslot");
    var returnVal = true;
    for(var c=0;c<peopleArray.length;c++) {
      $(peopleArray[c]).removeClass("wrong");
      var correctAge = peopleArray[c].dataset.age;
      var guess = $(peopleArray[c]).find("li");
      if(guess.length>0) {
        var guessedAge = guess[0].dataset.age;
        if(guessedAge!=correctAge) {
          $(peopleArray[c]).addClass("wrong");
          returnVal = false;
        }
      } else {
        // No age put for this person
        returnVal = false;
      }
    }

    /* If the returnVal is false (user got the matches wrong. And the attempts
     * are less than the argument, then go ahead and return false.
     * If the matches are wrong but the attempts are greater than the argument
     * then return true.
     * Of course, if the matches are right then return true.
     */

    var count = $(step).find("div#try_counter").attr("attempts");
    $(step).find("span#attempt_counter").html(parseInt((countLimit-count)/2));
    $(step).find("div#try_counter").attr("attempts",++count);

    if(!returnVal) {
      if(countLimit <= count) {
        resetAges();
        ageSort.option("disabled",true);
        return true;
      } else {
        return false;
      }
    }
    return returnVal;
  };

  Evaluations.prototype.countTries = function(step,countLimit) {
    var count = $(step).find("div#try_counter").attr("attempts");
    $(step).find("span#attempt_counter").html(countLimit-count);
    $(step).find("div#try_counter").attr("attempts",++count);
    return (countLimit < count);
  };

  return Evaluations;

})();
