var GoogleMusic = require("googlemusicapi").GoogleMusicApi;

var googlemusic = new GoogleMusic( );
googlemusic.Login(function () {
    googlemusic.GetAllSongs('', function(result) {
        var length = result.length;
        var i;
        for (i=0 ; i<length ; i++) {
            console.log(result[i].title); // get title of all songs 
        }
    });
    googlemusic.GetPlaylist('All', function(result) {
        var length = result.length;
        var i;
        for (i=0 ; i<length ; i++) {
            console.log(result[i].playListId); // get id of all playlists 
        }
    });
});