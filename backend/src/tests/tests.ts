import chai from "chai";
import chaiHttp from "chai-http";

import { app } from "..";

chai.use(chaiHttp);

//TODO have only one describe for each endpoint with many it's

describe("POST /add", () => {
  beforeEach(() => {
    const jsonRes = { words: ["foo", "bar"] };
  });
  //Checks if we can add a synonym pair
  it("should add a synonym pair", (done) => {
    chai
      .request(app)
      .post("/add")
      .send({ words: ["car", "auto"] })
      .end((err, res) => {
        chai.expect(res).to.have.status(201);
        done();
      });
  });
  //Checks if we can add more synonyms to an existing pair
  it("should add a new synonyms to existing word", (done) => {
    chai
      .request(app)
      .post("/add")
      .send({ words: ["auto", "volvo", "WV"] })
      .end((err, res) => {
        chai.expect(res).to.have.status(201);
        done();
      });
  });

  //Checks that we get an error if we try to add only one word
  it("should return an error when adding 1 word", (done) => {
    chai
      .request(app)
      .post("/add")
      .send({ words: ["car"] })
      .end((err, res) => {
        chai.expect(res).to.have.status(400);
        chai.expect(res).to.be.json;
        chai.expect(res.body).to.have.property("error");
        done();
      });
  });
});

describe("GET /find", () => {
  //Checks that we return the synonyms we added before
  it("should return the synonyms added before", (done) => {
    chai
      .request(app)
      .get("/find?word=car")
      .send()
      .end((err, res) => {
        chai.expect(res).to.have.status(200);
        chai.expect(res).to.be.json;
        chai.expect(res.body).to.have.property("message");
        chai
          .expect(res.body.message)
          .to.deep.equal(["car", "auto", "volvo", "WV"]);
        done();
      });
  });

  //Checks that we get 404 when we look for words we have not added
  it("should return an error 404 when we search for non existing word", (done) => {
    chai
      .request(app)
      .get("/find?word=foo")
      .send()
      .end((err, res) => {
        chai.expect(res).to.have.status(404);
        chai.expect(res).to.be.json;
        chai.expect(res.body).to.have.property("error");
        done();
      });
  });

  //Checks that we get an error when we don't include query
  it("should return an error 400 when we don't include query", (done) => {
    chai
      .request(app)
      .get("/find")
      .send()
      .end((err, res) => {
        chai.expect(res).to.have.status(400);
        chai.expect(res).to.be.json;
        chai.expect(res.body).to.have.property("error");
        done();
      });
  });
});
