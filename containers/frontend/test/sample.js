const app = require('../index');

const chai = require('chai');
const chaiHttp = require('chai-http');

chai.use(chaiHttp);
chai.should();

describe('API /healthz', () => {
    it('it should return 200', (done) => {
        chai.request(app)
            .get('/healthz')
            .end((err, res) => {
                res.should.have.status(200);
                done();
            });
    });
});

describe('API /', () => {
    it('it should return Welcome message', (done) => {
        chai.request(app)
            .get('/')
            .end((err, res) => {
                res.should.have.status(200);
                res.should.to.be.html;
                res.text.should.be.equal("Hello Docker World\n");
                done();
            });
    });
});

describe('API /hash/tali', () => {
    it('it should return sha256 hash of tali', (done) => {
        chai.request(app)
            .get('/hash/tali')
            .end((err, res) => {
                res.should.have.status(200);
                res.should.to.be.html;
                res.text.should.be.equal("qb20EHhTSFH1ge0ksVNW6UKhKougae8+X+en6uLjm8w=");
                done();
            });
    });
});

