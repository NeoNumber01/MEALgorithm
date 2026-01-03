const fs = require('fs');
const pngToIcoModule = require('png-to-ico');

const pngToIco = pngToIcoModule.default || pngToIcoModule;

console.log('Type of pngToIco:', typeof pngToIco);

if (typeof pngToIco === 'function') {
    pngToIco('public/images/MEAL_icon.png')
        .then(buf => {
            fs.writeFileSync('public/images/icon.ico', buf);
            console.log('Successfully generated public/images/icon.ico');
        })
        .catch(err => {
            console.error('Error generating ICO:', err);
            process.exit(1);
        });
} else {
    console.error('png-to-ico export is not a function:', pngToIcoModule);
    process.exit(1);
}
