---
---
function randomCover()
{
  var coverUrls = [
    {% for cover in site.data.covers %}
      'url({{ cover }})',
    {% endfor %}
  ];

  var cover = document.getElementById('cover');
  if (cover !== null) {
    cover.style.backgroundImage = coverUrls[Math.floor(Math.random() * coverUrls.length)];
  }
}
