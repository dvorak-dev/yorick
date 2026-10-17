const MAX_LENGTH = 4;

const RULES = {
  B: "bee",
  C: "cee",
  D: "dee",
  F: "eff",
  G: "gee",
  H: "aitch",
  J: "jay",
  K: "kay",
  L: "ell",
  M: "em",
  N: "en",
  P: "pee",
  Q: "queue",
  R: "ar",
  S: "ess",
  T: "tee",
  V: "vee",
  W: "skipOne",
  X: "ex",
  Z: "zee",
};

function primary(word) {
  return new Encoder(word).primary();
}

class Encoder {
  constructor(word) {
    this.word = String(word).toUpperCase().replace(/[^A-Z]/g, "");
    if (/^(GN|KN|PN|WR|PS)/.test(this.word)) this.word = this.word.slice(1);
    this.code = "";
    this.index = 0;
  }

  primary() {
    while (this.index < this.word.length && this.code.length < MAX_LENGTH) this.consume();
    return this.code;
  }

  consume() {
    const rule = this.ruleFor(this.current());
    this[rule]();
  }

  ruleFor(char) {
    if ("AEIOUY".includes(char)) return "vowel";
    return RULES[char] || "skipOne";
  }

  vowel() {
    if (this.index === 0) this.add("A");
    this.index += 1;
  }

  bee() {
    this.add("P");
    this.advance("B");
  }

  cee() {
    this.add(this.frontVowel() ? "S" : "K");
    this.index += 1;
  }

  dee() {
    this.add("T");
    this.advance("D");
  }

  eff() {
    this.add("F");
    this.advance("F");
  }

  gee() {
    this.add(this.frontVowel() ? "J" : "K");
    this.advance("G");
  }

  aitch() {
    this.index += 1;
  }

  jay() {
    this.add("J");
    this.index += 1;
  }

  kay() {
    this.add("K");
    this.advance("K");
  }

  ell() {
    this.add("L");
    this.advance("L");
  }

  em() {
    this.add("M");
    this.advance("M");
  }

  en() {
    this.add("N");
    this.advance("N");
  }

  pee() {
    if (this.ahead() === "H") {
      this.add("F");
      this.index += 2;
    } else {
      this.add("P");
      this.index += 1;
    }
    if (this.ahead(0) === "P") this.advance("P");
  }

  queue() {
    this.add("K");
    this.index += 1;
  }

  ar() {
    this.add("R");
    this.advance("R");
  }

  ess() {
    this.add("S");
    this.advance("S");
  }

  tee() {
    this.add("T");
    this.advance("T");
  }

  vee() {
    this.add("F");
    this.index += 1;
  }

  ex() {
    this.add("KS");
    this.index += 1;
  }

  zee() {
    this.add("S");
    this.advance("Z");
  }

  skipOne() {
    this.index += 1;
  }

  advance(char) {
    this.index += this.ahead() === char ? 2 : 1;
  }

  frontVowel() {
    const next = this.ahead();
    return Boolean(next) && "EIY".includes(next);
  }

  add(text) {
    this.code = (this.code + text).slice(0, MAX_LENGTH);
  }

  current() {
    return this.word[this.index];
  }

  ahead(offset = 1) {
    return this.word[this.index + offset];
  }
}

export { primary };
