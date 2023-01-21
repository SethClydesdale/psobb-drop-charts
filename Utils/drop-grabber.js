// script used for grabbing drop charts from ephinea
// https://ephinea.pioneer2.net/drop-charts/normal/

// HOW TO USE
// Paste the script in your console (F12/CTRL+SHIFT+I > Console) and execute it while viewing a drop chart,
// the lua table will automatically be copied to your clipboard.
// Delete the contents of the respective difficulty file (i.e. normal, hard, very hard, etc...)
// once you've done this, paste the previously copied code and save.
// Repeat the above steps for each difficulty.

// removes empty cells
$('tr').filter(function () {
  if (this.querySelector('td[colspan="11"]')) {
    return false
  } else {
    return this.innerHTML.indexOf('&nbsp;') != -1
  }
}).remove()

// key list for identifying section id by color
var section_id = {
  '#00A562' : 'Viridia',
  '#76FE43' : 'Greenill',
  '#59F9F9' : 'Skyly',
  '#4488FF' : 'Bluefull',
  '#CC00FF' : 'Purplenum',
  '#FF87CB' : 'Pinkal',
  '#F70F0F' : 'Redria',
  '#F7830F' : 'Oran',
  '#F7F715' : 'Yellowboze',
  '#FFFFFF' : 'Whitill'
}

const rgb2hex = (rgb) => `#${rgb.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/).slice(1).map(n => parseInt(n, 10).toString(16).padStart(2, '0')).join('')}`;

// loop vars
var chart = {},
    table = document.querySelectorAll('table'),
    i = 0,
    j = table.length,
    td, k, l, m, enemy, episode, b, abbr, dar, rare;

// loop over the table cells to retrieve the drop chart data
for (; i < j; i++) {
  td = table[i].querySelectorAll('td');
  episode = td[0].innerText;
  k = 1;
  l = td.length;

  console.log(episode)

  if (chart[episode]) {
    episode += ' Boxes'
    chart[episode] = {};
  } else {
    chart[episode] = {};
  }
  
  for (; k < l; k++) {
	backGroundColor = rgb2hex(getComputedStyle(td[k]).backgroundColor).toUpperCase();
    if (section_id[backGroundColor]) {
      if (!chart[episode][section_id[backGroundColor]]) {
        chart[episode][section_id[backGroundColor]] = []
      }

      b = td[k].querySelector('b');
      abbr = td[k].querySelector('abbr');
      dar = abbr ? abbr.title.match(/Drop Rate:.*?\((.*?)%\)/) : '';
      rare = abbr ? abbr.title.match(/Rare Rate:.*?\((.*?)%\)/) : '';

      // calculate the rare percent of boxes which don't explicitly show the percentage
      if (!abbr && td[k].querySelector('sup')) {
        // example : ((1 / 1170.29) * 100).toFixed(5)
        rare = [
          'Rare Rate', 
          ((+td[k].querySelector('sup').innerText / +td[k].querySelector('sub').innerText) * 100)
        ];
      }
      
      // only push if there's data available
      if (abbr || td[k].querySelector('sup')) {
        chart[episode][section_id[backGroundColor]].push({
          target : enemy,
          item : b ? b.innerText : '',
          dar : dar && dar[1] ? parseFloat(dar[1]) : 100,
          rare : rare && rare[1] ? parseFloat(rare[1]).toFixed(5) : 0
        });
      }

    } else if (td[k].colSpan == 11) {
      
      for (m in chart[episode]) {
        chart[episode][m].push({
          target : 'SEPARATOR'
        });
      }
      
    } else {
      enemy = td[k].innerText;
    }
  }
}

// stringify the object and convert it to lua table syntax, then copy it to the clipboard
copy('return ' + JSON.stringify(chart, null, 2).replace(/"(.*?)":/g, '["$1"] =').replace(/= \[/g, '= {').replace(/\],/g, '},').replace(/    ]\n  }/g, '    }\n  }').replace(/%/g, '%%').replace(/⁄/g, '/').replace(/\\r/g, '\\n').replace(/\["rare"\] = "(.*?)"/g, '["rare"] = $1'));

console.log('DROP CHARTS COPIED');
