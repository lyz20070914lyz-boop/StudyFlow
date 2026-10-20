# 行为评估

用例覆盖触发与输出约束，不验证长期学习效果。

元数据、内部链接、发布范围与用例结构可先运行 `ruby scripts/validate_skill.rb` 检查。这是静态检查，以下模型行为评估仍需另行运行。

## 运行方式

1. 在目标客户端安装 StudyFlow，确认 Skill 可发现。避免同时启用旧版。
2. 每条用例使用独立新对话，保持相同模型与其他 Skill 配置。负例不能手动指定 StudyFlow。
3. 原样发送 CSV 中的 prompt；需要材料的用例允许模型请求材料或先执行可完成的诊断，但不能伪造题目与作答。验证具体纠错能力时另补真实题与答案。
4. 根据实际读取 Skill 的记录判断触发，不能只靠回答自称“已触发”。记录模型、日期、启用的其他 Skill、是否触发和是否满足 expected_behavior。
5. 多轮用例继续提供真实作答，检查提示是否升级恰当、是否等待回答、是否凭空宣称掌握。

## 关注指标

- 应触发却未触发的数量。
- 不应触发却触发的数量。
- 已触发但忽略用户要求、虚构历史或一次倾倒流程的数量。
- 实际学习帮助是否对准已展示的错误。

可用“通过、未通过、未测试”记录每项，不填估算分数。运行可能产生模型费用，按实际环境决定是否批量执行。71 条用例未逐条运行。

## 0.3.0 已做的检查

[行为检查记录](behavior-check-0.3.0.md) 包含独立评估者对八个示例的实际输出与作者核查。八项均符合对应约束，其中语言练习与流程练习仅检查首轮，保存进度仅检查位置授权边界。

这不是 71 条用例全量通过，也不是独立新会话中的客户端自动触发测试。未验证真实文件保存、音频评分、多轮辅导或学习效果。具体范围与模型记录限制以报告为准。

## Evaluation scope (English)

Run each CSV prompt in a fresh conversation with the same model and enabled skills. Do not explicitly invoke StudyFlow for negative cases. Use actual skill-read traces to determine selection rather than trusting the answer's self-report. Grade behavior against expected_behavior, allowing valid wording differences. For multi-turn cases, provide real attempts and check help adjustment and source-checked feedback.

Static checks do not call a model. The [0.3.0 forward check](behavior-check-0.3.0.md) covers eight explicit-invocation fixtures in one evaluator context, not the full 71-case suite or automatic discovery. Real file writes, audio assessment, multi-turn teaching and educational outcomes remain untested.
