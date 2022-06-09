function initMap() {
    let longitude = parseFloat(document.getElementById("longitude").value);
    let latitude  = parseFloat(document.getElementById("latitude").value);

    //console.log(longitude);
    //console.log(latitude);

    let map = new google.maps.Map(document.getElementById('map'), {
        center: { lat: latitude, lng: longitude },
        zoom: 15,
    });
    //console.log(map);
}
