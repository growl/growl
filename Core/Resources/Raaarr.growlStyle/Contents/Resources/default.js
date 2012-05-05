/*
Copyright (c) The Growl Project, 2011
All rights reserved.


Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:


1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of Growl nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.


THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

var outer = document.getElementById('outer');
var icon = document.getElementById('icon');
var iconshadow = document.getElementById('iconshadow');

icon.addEventListener('load', function() {

    // some extra work to deal with Growl defaulting opacity to 95% for webkit-based styles.
    // since we have a lot of subtle opacity effects, we want to be able to have opacity:1 stuff
    // for contrast. If you really want to lower opacity manually in the control panel (why?)
    // just set it below 95%.
    if (window.growlOpacity >= 0.95)
        window.growlOpacity = 1;

    // create the icon shadow based on the final loaded size of the icon    
    iconshadow.style.width = (icon.offsetWidth + 2) + "px";
    iconshadow.style.height = (icon.offsetHeight + 2) + "px";
    
    // trigger animations now that we've tweaked the element so it will rerender before appearing.
    outer.style.opacity = window.growlOpacity;
    outer.style.webkitAnimationName = "bubble";
});