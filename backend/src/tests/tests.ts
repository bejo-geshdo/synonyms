import chai from "chai";
import chaiHttp from "chai-http";

import { app } from "..";

chai.use(chaiHttp);

describe("POST /add", () => {
  it("should add a new item", (done) => {
    chai
      .request(app)
      .post("/add")
      .send({ words: ["car", "auto"] })
      .end((err, res) => {
        chai.expect(res).to.have.status(201);
        done();
      });
  });
});

describe("POST /add to few words", () => {
  it("should return an error", (done) => {
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
  it("should return the items added before", (done) => {
    chai
      .request(app)
      .get("/find?word=car")
      .send()
      .end((err, res) => {
        chai.expect(res).to.have.status(200);
        chai.expect(res).to.be.json;
        chai.expect(res.body).to.have.property("message");
        chai.expect(res.body.message).to.deep.equal(["car", "auto"]);
        done();
      });
  });
});

describe("GET /find word not in app", () => {
  it("should return an error 404", (done) => {
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
});

describe("GET /find missing word", () => {
  it("should return an error 400", (done) => {
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
