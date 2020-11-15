	var util = require('util');
	var bleno = require('bleno');
//	var date = require('');

	 // gpio vars
	var Gpio = require('onoff').Gpio,
	    pin_lock = new Gpio(4, 'out'),   
	    green_led = new Gpio(16, 'out'),  
	    blue_led = new Gpio(20, 'out'),  
	    red_led = new Gpio(21, 'out'),
	    relay_power = new Gpio(26, 'out'), //relay power on
	    relay_test = new Gpio(7, 'out'); //relay start test
// 
	var PrimaryService = bleno.PrimaryService;
	var Characteristic = bleno.Characteristic;
	var Descriptor = bleno.Descriptor;
	var secret0 = '3123';
	var secret1 = "0xFF"
/*
    insert relay_status
 */
    var relay_statusCharacteristic = function() {
  		relay_statusCharacteristic.super_.call(this, {
    		uuid: 'd281',
    		properties: ['write', 'writeWithoutResponse'],
    		descriptors: [
      			new Descriptor({
        		uuid: '2109',
        		value: 'Relay Status'
      		})
    	]
	  });
	}
	util.inherits(relay_statusCharacteristic, Characteristic);

	relay_statusCharacteristic.prototype.onWriteRequest = function(data, offset, withoutResponse, callback) {
      var relay_status{
      	if (pin_lock.readSync() = 1) {
	    	relay_status = 'ready'; 
	    	power_relay.writeSync(1); // turn ON power switch    if pin_lock.readSync(1
	    	green_led.writeSync(1); // flash green_led
			bleno.setServices([relayService]); 
	  	    console.log('power relay is ON');   	  
	    	console.log('test relay status: ' + relay_status);
	     }
	 	else {
	    	relay_status = 'not ready';
	    	power_relay.writeSync(0); // do NOT turn ON powerr switch
	    	console.log('power relay is OFF');
	    	console.log('test relay status: ' + relay_status);
	  //  option to enter pin or reset
	  }
	}
	  // reset pin code lock and lights after x seconds
	  setTimeout(this.reset.bind(this), 100000);
	  callback(this.RESULT_SUCCESS);
	  this.emit('relay_status', relay_status);
	};
	// close the lock and reset the lights
	relay_statusCharacteristic.prototype.reset = function() {
	  this.emit('relay_status', 'ready');
	  blue_led.writeSync(1);  //
	  green_led.writeSync(1); //
	 
	}
/*
    relay_test 
*/	

    var relay_testCharacteristic = function() {
	  relay_testCharacteristic.super_.call(this, {
    	uuid: '0xFF',
    	properties: ['write', 'writeWithoutResponse'],
    	descriptors: [
      		new BlenoDescriptor({
        	uuid: '2901',
        	value: 'relay_test'
      })
    ]
  });
}

util.inherits(relay_testCharacteristic, BlenoCharacteristic);

relay_testCharacteristic.prototype.onWriteRequest = function(data, offset, withoutResponse, callback) {

	  if (data.toString() === secret2) {
	    relay_status = 'Active';
	    relay_power.writeSync(1); // power relay on
	    relay_test.writeSync(1); // test relay on
	    green_led.writeSync(1); //green
	  } else {
	    relay_status = 'Ready';
	    relay_power.writeSync(1); // power relay on
	    relay_test.writeSync(0); // test relay NOT on	    
	    red_led.writeSync(1); // red led
	  }
	  // reset pin code lock and lights after 240 seconds
	  setTimeout(this.reset.bind(this), 240000);
};



/*
          pin code unlock
*/
	var UnlockCharacteristic = function() {
	    UnlockCharacteristic.super_.call(this, {
	      uuid: 'd271',
	      properties: ['write'],
	      descriptors: [
	         new Descriptor({
	           uuid: '2901',
	           value: 'Pin Code Unlock'
	         })
	      ]
	    });
	  };
	util.inherits(UnlockCharacteristic, Characteristic);

	UnlockCharacteristic.prototype.onWriteRequest = function(data, offset, withoutResponse, callback) {
	  var status;
	  if (data.toString() === secret0) {
	    status = 'unlocked';
	    pin_lock.writeSync(1); // gpio function why
	    green_led.writeSync(1); // make greem_led flash now
	  } else {
	    status = 'invalid code';
	    pin_lock.writeSync(0); // dont open the door!
	    red_led.writeSync(1); // make red_led flash now
	  }
	  // reset pin code lock and lights after x seconds
	  setTimeout(this.reset.bind(this), 3600000);

      console.log('unlock: ' + data);
   	  console.log('status: ' + status);
	  callback(this.RESULT_SUCCESS);
	  this.emit('status', status);
	};

	// close the lock and reset the lights
	UnlockCharacteristic.prototype.reset = function() {
	  this.emit('status', 'locked');
	  pin_lock.writeSync(0);  //lock
	  green_led.writeSync(1); //greenled
	 
	}
/*
  new var           Current status of the lock
*/	
	var StatusCharacteristic = function(unlockCharacteristic) {
	    StatusCharacteristic.super_.call(this, {
	      uuid: 'd272',
	      properties: ['notify'],
	      descriptors: [
	         new Descriptor({
	           uuid: '2901',
	           value: 'Enter Code to Unlock Test Machine:'
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

/*
    ble services
*/
	var lockService = new PrimaryService({
	  uuid: 'd270',
	  characteristics: [
	    unlockCharacteristic, 
	    statusCharacteristic
	  ]
	});

	var relayService = new PrimaryService({
	  uuid: 'd280',
	  characteristics: [
	    relay_statusCharacteristic, 
	    relay_testCharacteristic
	    ]
	});

/*---------------------------
    bleno.on
-----------------------*/

	bleno.on('stateChange', function(state) {
	   console.log('on -> stateChange: ' + state);
	  if (state === 'poweredOn') {
	    bleno.startAdvertising('leightonobrien', [lockService.uuid]);
		blue_led.writeSync(1);	  
	  } 
	  else {
	    bleno.stopAdvertising();
	  	blue_led.writeSync(0);	
	  	red_led.writeSync(0);	
	  	green_led.writeSync(0);	
	    relay_test.writeSync(0);
	    relay_power.writeSync(0);	
	  }
	});

	bleno.on('advertisingStart', function(error) {
	  console.log('on -> advertisingStart: ' + (error ? 'error ' + error : 'success'));
	  
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

/*   errors
            handleAttribute.emit('unsubscribe');
 */


/*
function relay_testCharacteristic() {
  relay_testCharacteristic.super_.call(this, {
    uuid: '0xFF',
    properties: ['write', 'writeWithoutResponse'],
    descriptors: [
      new BlenoDescriptor({
        uuid: '2901',
        value: 'relay_test'
      })
    ]
  });
}

util.inherits(relay_testCharacteristic, BlenoCharacteristic);

relay_testCharacteristic.prototype.onWriteRequest = function(data, offset, withoutResponse, callback) {

	  if (data.toString() === secret2) {
	    relay_status = 'Active';
	    relay_power.writeSync(1); // power relay on
	    relay_test.writeSync(1); // test relay on
	    green_led.writeSync(1); //green
	  } else {
	    relay_status = 'Ready';
	    relay_power.writeSync(1); // power relay on
	    relay_test.writeSync(0); // test relay NOT on	    
	    red_led.writeSync(1); // red led
	  }
	  // reset pin code lock and lights after 240 seconds
	  setTimeout(this.reset.bind(this), 240000);
};

*/





/*
    if pin_lock.readSync(1) === {
      bleno.setServices([testService]);
      bleno.setServices([relayService]); 
  }
    
  led.writeSync(led.readSync() ^ 1);


	relay_statusCharacteristic.prototype.onWriteRequest = function(pin_lock, power_relay, green_led, red_led, withoutResponse, console) {
	  var relay_status;

	  if (pin_lock.readSync() = 1) {
	    relay_status = 'ready'; 
	    power_relay.writeSync(1); // turn ON power switch    if pin_lock.readSync(1
	    green_led.writeSync(1); // flash green_led
//      bleno.setServices([testService]);
        bleno.setServices([relayService]); 
	    console.log('power relay is ON');   	  
	    console.log('test relay status: ' + relay_status);
	      //
	  } else {
	    relay_status = 'not ready';
	    power_relay.writeSync(0); // do NOT turn ON powerr switch
	    red_led.writeSync(1); // flash red_led
	    console.log('power relay is OFF');
	    console.log('test relay status: ' + relay_status);
	  */

