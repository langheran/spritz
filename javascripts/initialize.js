var SpritzLoaded = false
SPRITZ_Popup = {		
	panel:null,
	controller:null,
	speedSlider:null,
    speedLabel:null,
    speed:250,	
	progressBar:{
		show: false,
		content: null
	},
	
	customOptions:{
		debugLevel:         1,                                          // Set debug level to 3 for verbose output
		defaultSpeed: 	    250, 									    // Specify default speed
		controlButtons: 	["rewind", "back", "pauseplay", "forward"],	// Specify a single control button
		header: {
				login: false,
				close: false,
				closeHandler: function(){SPRITZ_Popup.closePopup();}
		},
		placeholderText: {
			startText: 'Loading...'                          // Specify start text
		},
		redicle: {
			countdownTime: 750,                                        // Specify countdown time
			countdownSlice: 1,                                           // Specify countdown slice
			backgroundColor: "#ffffff",
        	textNormalPaintColor: "#000000",
        	textHighlightPaintColor: "#ff0000", // Red ORP
		}
	},
	
	reticleStyle:{
		small: {redicleWidth:285,redicleHeight:50},		
		normal: {redicleWidth:340,redicleHeight:70},
		large: {redicleWidth:600,redicleHeight:120}
	},
	
	
	sendMessageToBackground : function(data){
		 //chrome.runtime.sendMessage({ SPRITZmsg: data });
	},
	
	receiveMessageFromBackground : function(event) {
		var action = event.SPRITZmsg && event.SPRITZmsg.action;

		switch(action) {
			case 'showText':
				SPRITZ_Popup.showText(event.SPRITZmsg);
				break;		
			case 'showTextFromUrl':
				SPRITZ_Popup.showTextFromUrl(event.SPRITZmsg.url);
				break;		
			case 'rewind':
				SPRITZ_Popup.controller.backBtn.click();
				break;	
			case 'pause':
				SPRITZ_Popup.togglePause();
				break;			
			case 'showProgressBar':
				SPRITZ_Popup.showProgressBar(event.SPRITZmsg.value);
				break;                
			case 'changeBackgroundColor':
				SPRITZ_Popup.changeBackgroundColor(event.SPRITZmsg.value);
				break;            
			case 'changeFontColor':
				SPRITZ_Popup.changeFontColor(event.SPRITZmsg.value);
				break;            
			case 'changeFocusColor':
				SPRITZ_Popup.changeFocusColor(event.SPRITZmsg.value);
				break;
		}
	},
	
	closePopup : function(){
		SPRITZ_Popup.sendMessageToBackground({ action: 'closeReader' });
	},
	
	setSpeed : function(speed){
		if (SPRITZ_Popup.panel && SPRITZ_Popup.panel.setCurrentTextSpeed(speed)){
			//chrome.storage.sync.set({SPRITZ_Speed: speed});
			SPRITZ_Popup.speed = speed;
			SPRITZ_Popup.speedLabel.innerHTML = speed;
			SPRITZ_Popup.speedSlider.value = speed;
		}else{
			SPRITZ_Popup.speedSlider.value = SPRITZ_Popup.speed;
		}			
	},
	
	togglePause : function() {
		SPRITZ_Popup.controller.pausePlayBtn.click();
	},
	
	onSpeedSelectorChange : function(){
		SPRITZ_Popup.setSpeed(this.value);
	},
	
	onKeyDown : function(event) {
		if(event.keyCode == 37) {
			SPRITZ_Popup.receiveMessageFromBackground({ SPRITZmsg: { action: 'rewind' } });
		}else if(event.keyCode == 17) {
			SPRITZ_Popup.togglePause();
		}else if(event.keyCode == 27) {
			SPRITZ_Popup.closePopup();
		}
	},
		
	showText : function(params) {	
		// Retry until SpritzClient is loaded.
		// May happen when Spritz is not loaded from cache
		if (typeof SpritzClient == "undefined") {
			setTimeout(function(){SPRITZ_Popup.showText(params);},100);
			return;
		}
		
		if (params.text){
			SpritzClient.spritzify(params.text, "en_us", SPRITZ_Popup.onSpritzifySuccess, SPRITZ_Popup.onSpritzifyError);		
		}else if (params.fileType == 'application/pdf' && params.url){
			if (SPRITZ_Popup.isLocalFileUrl(params.url)){
				SPRITZ_Popup.closePopup();
				alert("Cannot read local file. Please select text using the mouse or the keyboard shortcut CTRL+A, then right click the content and select Spritz from the contextual menu.");
			}else{
				SpritzClient.fetchContents2(params.url, SPRITZ_Popup.onSpritzifySuccess, SPRITZ_Popup.onFetchContentError, { selectorType: 'PDF', includePlainText: true });
			}
		}else if (params.url){
			SpritzClient.fetchContents(params.url, SPRITZ_Popup.onSpritzifySuccess, SPRITZ_Popup.onFetchContentError, 'p');
		}else{ // error occured
			SPRITZ_Popup.displayShortMessage("Unable to Spritz...");	
		}
	},
	
	onSpritzifySuccess : function(spritzText) {
		// TODO: remove the last pause at the end
		SPRITZ_Popup.controller.startSpritzing(spritzText);
	},
	
	onSpritzifyError : function(error) {
		console.log("Unable to Spritz: " + error.message);
		SPRITZ_Popup.displayShortMessage("Unable to Spritz...");		
	},
	
	onFetchContentError : function(error) {
		console.log("Unable to Fetch content: " + error.message);
		SPRITZ_Popup.displayShortMessage("Unable to Fetch");	
	},
	
	onCompleted : function() {
		SPRITZ_Popup.closePopup();
	},
	onRewind : function() {
		SPRITZ_Popup.togglePause();
	},
	onForward : function() {
		SPRITZ_Popup.togglePause();
	},
	onBack : function() {
		SPRITZ_Popup.togglePause();
	},
	onProgressChange : function(progress, total) {
		$("#spritz_progress_bar").width(progress/total*100 + "%");
	},
	
	addCustomControls : function() {
		$('<div id="speed-value"></div><div class="btn-group custom-speed-controller"><input id="speed" type="range" min="100" max="1000" step="50" /></div>').insertBefore($("#spritzer .spritzer-controls-container .spritzer-button-container"))
		SPRITZ_Popup.speedSlider = document.getElementById('speed');
		SPRITZ_Popup.speedLabel = document.getElementById('speed-value');
		SPRITZ_Popup.speedSlider.addEventListener('input', SPRITZ_Popup.onSpeedSelectorChange);
		SPRITZ_Popup.setSpeed(SPRITZ_Popup.speed);
		$('<div id="spritz_progress_bar_container"><div id="spritz_progress_bar"></div></div> ').insertAfter($("#spritzer .spritzer-controls-container"))
		
		$('<div id="speakmode-value" style="position: absolute; left: 100px; top: 10px" >Spritz mode</div>').insertBefore($("#spritzer .spritzer-header"))
		
		/*$('<div id="sentence" style="background-color: white; position: absolute; left: 0px; top: -140px" ></div>').insertBefore($("#spritzer .spritzer-header"))*/
	},
	
	showProgressBar : function(show) {
		if (show == true ){
			document.getElementById("spritz_progress_bar").style.display = 'block';
		}else{
			document.getElementById("spritz_progress_bar").style.display = 'none';
		}
	},    
    
	changeBackgroundColor : function(newColor) {
		SPRITZ_Popup.customOptions.redicle.backgroundColor = newColor;
        SPRITZ_Popup.customApplyOptions(SPRITZ_Popup.customOptions);
        $(".spritzer-container").css("backgroundColor", newColor);
	},
	changeFontColor : function(newColor) {
		SPRITZ_Popup.customOptions.redicle.textNormalPaintColor = newColor;
        SPRITZ_Popup.customApplyOptions(SPRITZ_Popup.customOptions);
        //This is to fix a bug with Spritz API that reset background color
        $(".spritzer-container").css("backgroundColor", SPRITZ_Popup.customOptions.redicle.backgroundColor);
	},
	changeFocusColor : function(newColor) {
		SPRITZ_Popup.customOptions.redicle.textHighlightPaintColor = newColor;
        SPRITZ_Popup.customApplyOptions(SPRITZ_Popup.customOptions);
        //This is to fix a bug with Spritz API that reset background color
        $(".spritzer-container").css("backgroundColor", SPRITZ_Popup.customOptions.redicle.backgroundColor);
	},
	changeColors : function(newBackgroundColor, newFontColor, newFocusColor) {
		SPRITZ_Popup.customOptions.redicle.backgroundColor = newBackgroundColor;
		SPRITZ_Popup.customOptions.redicle.textNormalPaintColor = newFontColor;
		SPRITZ_Popup.customOptions.redicle.textHighlightPaintColor = newFocusColor;
        SPRITZ_Popup.customApplyOptions(SPRITZ_Popup.customOptions);
        $(".spritzer-container").css("backgroundColor", newBackgroundColor);
	},

	customApplyOptions : function(options) {		
        SPRITZ_Popup.controller.applyOptions(options);
        SPRITZ_Popup.addCustomControls();
	},
	
	displayShortMessage: function(msg) {
		if (SPRITZ_Popup.controller) {
			SPRITZ_Popup.controller.applyOptions({placeholderText: {startText: msg}});
		}		
	},	
	
	isLocalFileUrl: function(url){
		return url != undefined && url.slice(0,6) == "file:/";
	},
	
	init: function(){
		SpritzLoaded = false
		SPRITZ_Popup.sendMessageToBackground({ action: 'readerReady' });
		
		//chrome.runtime.onMessage.addListener(SPRITZ_Popup.receiveMessageFromBackground);
		
		var container = document.getElementById('spritzer');
		
		container.addEventListener("onSpritzComplete", SPRITZ_Popup.onCompleted);
		container.addEventListener("onSpritzRewind", SPRITZ_Popup.onRewind);
		container.addEventListener("onSpritzForward", SPRITZ_Popup.onForward);
		container.addEventListener("onSpritzBack", SPRITZ_Popup.onBack);
			
		document.addEventListener('keydown', SPRITZ_Popup.onKeyDown);
		
		$( document ).ready(function() {
		
			/*
				chrome.storage.sync.get({
					reticleSize:{redicleWidth:340,redicleHeight:70},
					SPRITZ_ShowProgressBar: true,
					SPRITZ_BackgroundColor: SPRITZ_Popup.customOptions.redicle.backgroundColor,
					SPRITZ_FontColor: SPRITZ_Popup.customOptions.redicle.textNormalPaintColor,
					SPRITZ_FocusColor: SPRITZ_Popup.customOptions.redicle.textHighlightPaintColor,
					SPRITZ_Speed: SPRITZ_Popup.speed
				}, 
				function(items) {					
					// Get this page's Spritzer container
					var container = $("#spritzer");
					// Attach the controller's container to this page's "spritzer" container
					SPRITZ_Popup.controller = new SPRITZ.spritzinc.SpritzerController(jQuery.extend(SPRITZ_Popup.customOptions, items.reticleSize)).attach(container);
				
					SPRITZ_Popup.addCustomControls();	
					SPRITZ_Popup.showProgressBar(items.SPRITZ_ShowProgressBar);	
					SPRITZ_Popup.changeColors(items.SPRITZ_BackgroundColor, items.SPRITZ_FontColor, items.SPRITZ_FocusColor);
					SPRITZ_Popup.panel = SPRITZ_Popup.controller.spritzPanel;
					SPRITZ_Popup.setSpeed(items.SPRITZ_Speed);
					
					SPRITZ_Popup.controller.setProgressReporter(SPRITZ_Popup.onProgressChange);
				}	
			);
			*/
			
			initItems = function(items) {					
					// Get this page's Spritzer container
					var container = $("#spritzer");
					// Attach the controller's container to this page's "spritzer" container
					SPRITZ_Popup.controller = new SPRITZ.spritzinc.SpritzerController(jQuery.extend(SPRITZ_Popup.customOptions, items.reticleSize)).attach(container);
				
					SPRITZ_Popup.addCustomControls();	
					SPRITZ_Popup.showProgressBar(items.SPRITZ_ShowProgressBar);	
					SPRITZ_Popup.changeColors(items.SPRITZ_BackgroundColor, items.SPRITZ_FontColor, items.SPRITZ_FocusColor);
					SPRITZ_Popup.panel = SPRITZ_Popup.controller.spritzPanel;
					SPRITZ_Popup.setSpeed(items.SPRITZ_Speed);
					
					SPRITZ_Popup.controller.setProgressReporter(SPRITZ_Popup.onProgressChange);
					SpritzLoaded = true
				};
			
			items={
					reticleSize:SPRITZ_Popup.reticleStyle.large,
					SPRITZ_ShowProgressBar: true,
					SPRITZ_BackgroundColor: SPRITZ_Popup.customOptions.redicle.backgroundColor,
					SPRITZ_FontColor: SPRITZ_Popup.customOptions.redicle.textNormalPaintColor,
					SPRITZ_FocusColor: SPRITZ_Popup.customOptions.redicle.textHighlightPaintColor,
					SPRITZ_Speed: SPRITZ_Popup.speed
				};
			initItems(items);
				
			
			
			
		});
	}
};
SPRITZ_Popup.init();