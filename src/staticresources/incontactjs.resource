//removes btn style from buttons
function StyleButtons(){
	$('.k-button.btn').removeClass('btn'); 
}

//closes console subtab
function CloseSubTab() {
	//First find the ID of the current tab to close it
        sforce.console.getEnclosingTabId(closeSubtabVar);
}
        
var closeSubtabVar = function closeSubtabVar(result) {
	//Now that we have the tab ID, we can close it
        var tabId = result.id;
        sforce.console.closeTab(tabId);
};


    function ChangeSelectsIntoButtons()
    {
            $('select').each(function(selectIndex, selectElement){
                if($(selectElement).siblings('div.k-listview').size() == 0 && 
                    (($(selectElement).children('option[value!=""]').size() < 5 && $(selectElement).siblings('input').size() == 0) ||
                    ($(selectElement).attr('multiple') === 'multiple' && $(selectElement).is( ":hidden" ))))
                {
                    $(selectElement).hide();
                    $('<div>').addClass('k-listview').prependTo($(selectElement).parent());
                    $(selectElement).children('option[value!=""]').each(function(optionIndex, optionElement){
                        var link = $('<a>')
                            .addClass('k-button')
                            .attr('data-value', $(optionElement).attr('value'))
                            .attr('href', 'javascript:void(0);')
                            .attr('tabindex', '0')
                            .click(function(){SelectButtonClick(this);})
                            .html($(optionElement).html());
                        $(link).appendTo($(selectElement).siblings('div.k-listview'));
                        if($(selectElement).parents('[id*="RiskAssessmentFields"]').size() > 0)
                            $('<div style="clear:both;">').appendTo($(selectElement).siblings('div.k-listview'));
                            
                        if($(optionElement).attr('selected') === 'selected')
                        {
                            $(link).addClass('k-state-selected');
                        }
                    });
                }
                else if($(selectElement).siblings('input').size() > 0)
                {
                    $(selectElement).hide();
                }
                else if($(selectElement).siblings('div.k-listview').size() == 0)
                {
                //$(selectElement).addClass('k-secondary').kendoDropDownList();
                }
            });
            $('table.multiSelectPicklistTable').hide();  
    }


    function SelectButtonClick(selectButton){
        if($(selectButton).hasClass('k-state-selected')){
           //$(selectButton).parent().siblings('select').val('');
            $(selectButton).parent().siblings('select').children('option[value="' + $(selectButton).data('value') + '"]').prop("selected", false); 
            $(selectButton).removeClass('k-state-selected');
        }
        else
        {
        $(selectButton).parent().siblings('select').children('option[value="' + $(selectButton).data('value') + '"]').prop("selected", true);
        //$(selectButton).parent().siblings('select').val($(selectButton).data('value'));
        if($(selectButton).parent().siblings('select').attr('multiple') !== 'multiple')
            $(selectButton).siblings().removeClass('k-state-selected');
        $(selectButton).addClass('k-state-selected');
        }
    }



    /*
     * jQuery CSV Export Widget Plugin
     *
     * Adds a button to a containing element (specified by a jQuery selector) that calls a URL.
     * Once clicked, the button is replaced by a spinner and message.
     * When the URL call completes, the spinner and message are replace by the original button.
     *
     * Usage of 'options' argument:
     *      url = the base URL to call
     *      params = optional query string parameters to append to the URL (specified as 'key'/'value' pairs)
     *      message = the message to display next to the spinner
     *
     * Example:
     *      $(<jQuery selector>).exportWidget({
     *          url: '@Url.Action(<params>)'
     *          params: [
     *              { key: '<key1>', value: '<value1>' },
     *              { key: '<key2>', value: '<value2>' }
     *          ],
     *          message: '<your message>'
     *      });
     */

    jQuery.fn.exportWidget = function (options) {
        if (options.url !== undefined && options.url !== '' && options.url !== null) {
            var containingElement = this.selector;
            var spinner = createSpinner(containingElement, options);

            $('<a>')
                .addClass('incontact-button')
                .attr('data-role', 'export-button')
                .text('CSV Export')
                .click(function () {
                    buttonClick(containingElement, spinner, options);
                }).appendTo(containingElement);
        }
    }

    function createSpinner(containingElement, options) {
        var spinnerContainer = $('<div>')
            .attr('data-role', 'spinner-container')
            .appendTo(containingElement);

        var spinnerMessage;
        if (options.message === undefined)
            spinnerMessage = '&nbsp;';
        else
            spinnerMessage = options.message;

        spinnerContainer.append($('<div data-role="spinner-element" id="incontact-csv-export-widget-spinner"></div>'));
        spinnerContainer.append($('<div data-role="spinner-text">' + spinnerMessage + '</div>'));
        spinnerContainer.append($('<div class="clear-both"></div>'));

        var spinnerOptions = {
            top: -2,
            left: 0,
            lines: 9,
            length: 4,
            width: 3,
            radius: 6,
            corners: 1,
            color: '#f48B31',
            speed: 1.2,
            trail: 40
        };

        var spinner = new Spinner(spinnerOptions);

        return spinner;
    }

    function buttonClick(containingElement, spinner, options) {
        hideButton(containingElement);
        showSpinner(containingElement, spinner);

        var token = new Date().getTime().toString();
        downloadFile(token, options);

        var fileDownloadCheckTimer;

        fileDownloadCheckTimer = window.setInterval(function () {
            var cookieValue = $.cookie('token');

            if (cookieValue === token) {
                window.clearInterval(fileDownloadCheckTimer);
                $.removeCookie('token');
                showButton(containingElement);
                hideSpinner(containingElement, spinner);
            }
        }, 1000);
    }

    function showButton(containingElement) {
        $(containingElement).children('a[data-role="export-button"]').show();
    }

    function hideButton(containingElement) {
        $(containingElement).children('a[data-role="export-button"]').hide();
    }

    function showSpinner(containingElement, spinner) {
        $(containingElement).children('div[data-role="spinner-container"]').show();
        var spinnerElement = document.getElementById('incontact-csv-export-widget-spinner');

        spinner.spin(spinnerElement);
    }

    function hideSpinner(containingElement, spinner) {
        $(containingElement).children('div[data-role="spinner-container"]').hide();

        spinner.stop();
    }

    function downloadFile(token, options) {
        var fullUrl = options.url + '?token=' + token;

        if (options.params) {
            var parameters = options.params();

            $(parameters).each(function () {
                fullUrl += '&' + this.key + '=' + this.value;
            });
        }

        window.location = fullUrl;
    }