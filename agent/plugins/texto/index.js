module.exports = {
  actions: {
    type({ text, enter }, ctx) {
      if (text.length > 2000) throw new Error('texto grande demais (máx. 2000 caracteres)');
      ctx.typeText(text);
      if (enter === 'sim') ctx.pressKeys('enter');
    },
  },
};
