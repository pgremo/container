var assert=require('assert');
describe('Array',function(){
	describe('#indexOf',function(){
		it('should return -1 when the value is not present',function(){
			assert.equal(-1,[1,2,3].indexOf(5));
			assert.equal(-1,[1,2,3].indexOf(0));
		});
	});

	describe('#length',function(){
		it('should return a value >0',function(){
			assert.equal(3,[1,2,3].length);
			assert.equal(5,[1,2,3,4,5].length);
			assert.equal(5,[1,2,3,4,5].length);
		});
	});

});
