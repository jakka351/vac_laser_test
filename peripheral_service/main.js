  // requirements
  // bleno library requires bluetooth-hci-socket library, which works on node v8.9.0 for pib
var util = require('util');
var bleno = require('bleno');

 // gpio vars
var Gpio = require('onoff').Gpio,
    gpio04 = new Gpio(4, 'out'),   //greenled
    gpio16 = new Gpio(16, 'out'),  //redled
    gpio20 = new Gpio(20, 'out'),  //lock
    gpio21 = new Gpio(21, 'out'),
    gpio26 = new Gpio(26, 'out'),
    gpio07 = new Gpio(7, 'out');


  // service
var PrimaryService = bleno.PrimaryService;
var Characteristic = bleno.Characteristic;
var Descriptor = bleno.Descriptor;

var secret = '12345';

// write the secret to this Characteristic to unlock
var UnlockCharacteristic = function() {
    UnlockCharacteristic.super_.call(this, {
      uuid: 'd271',
      properties: ['write'],
      descriptors: [
         new Descriptor({
           uuid: '2901',
           value: 'Unlock'
         })
      ]
    });
  };
util.inherits(UnlockCharacteristic, Characteristic);

UnlockCharacteristic.prototype.onWriteRequest = function(data, offset, withoutResponse, callback) {
  var status;

  if (data.toString() === secret) {
    status = 'unlocked';
    gpio04.writeSync(1); //greenled
    lock.writeSync(1);   //lock
  } else {
    status = 'invalid code';
    gpio16.writeSync(1); //redled
  }

  // reset lock and lights after 4 seconds
  setTimeout(this.reset.bind(this), 4000);

   console.log('unlock: ' + data);
  console.log('status: ' + status);

  callback(this.RESULT_SUCCESS);

  this.emit('status', status);
};

// close the lock and reset the lights
UnlockCharacteristic.prototype.reset = function() {
  this.emit('status', 'locked');
  lock.writeSync(0);  //lock
  gpio04.writeSync(0); //greenled
  gpio16.writeSync(0); //redled
}

// Current status of the lock
var StatusCharacteristic = function(unlockCharacteristic) {
    StatusCharacteristic.super_.call(this, {
      uuid: 'd272',
      properties: ['notify'],
      descriptors: [
         new Descriptor({
           uuid: '2901',
           value: 'Enter Code to Start Test'
         })
      ]      
    });

    unlockCharacteristic.on('status', this.onUnlockStatusChange.bind(this));
  };
util.inherits(StatusCharacteristic, Characteristic);

StatusCharacteristic.prototype.onUnlockStatusChange = function(status) {
  if (this.updateValueCallback) {
    this.updateValueCallback(new Buffer(status));
  }
};

var unlockCharacteristic = new UnlockCharacteristic();
var statusCharacteristic = new StatusCharacteristic(unlockCharacteristic);

var lockService = new PrimaryService({
  uuid: 'd270',
  characteristics: [
    unlockCharacteristic, 
    statusCharacteristic
  ]
});

bleno.on('stateChange', function(state) {
  console.log('   -> Dri-Sump Containment Testing');
  console.log('on -> stateChange: ' + state);

  if (state === 'poweredOn') {
    bleno.startAdvertising('Dri-Sump', [lockService.uuid]);
  } else {
    bleno.stopAdvertising();
  }
});

bleno.on('advertisingStart', function(error) {
  console.log('on ->');
  console.log('on -> advertisingStart: ' + (error ? 'error ' + error : 'success'));
  console.log('on -> listening for incoming connection:');
  if (!error) {
    bleno.setServices([lockService]);
  }
});

// cleanup GPIO on exit
function exit() {
  console.log('exiting...');
  gpio04.unexport();
  gpio16.unexport();
  gpio20.unexport();
  gpio21.unexport();
  gpio26.unexport();
  gpio07.unexport();
  process.exit();
}
process.on('SIGINT', exit);
